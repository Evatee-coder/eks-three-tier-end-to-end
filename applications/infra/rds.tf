resource "aws_subnet" "rds_1" {
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"
  vpc_id            = data.aws_eks_cluster.eks.vpc_config[0]["vpc_id"]

  tags = {
    Name = "RDS Private Subnet 1 (active)"
  }
}

resource "aws_subnet" "rds_2" {
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"
  vpc_id            = data.aws_eks_cluster.eks.vpc_config[0]["vpc_id"]

  tags = {
    Name = "RDS Private Subnet 2 (standby)"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  vpc_id      = data.aws_eks_cluster.eks.vpc_config[0]["vpc_id"]
  description = "allow inbound access from the EKS only"

  ingress {
    description = "Postgres access from EKS cluster"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    security_groups = concat(
      [data.aws_eks_cluster.eks.vpc_config[0]["cluster_security_group_id"]],
      tolist(data.aws_eks_cluster.eks.vpc_config[0]["security_group_ids"]),
      [data.aws_security_group.eks_node.id]
    )
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  # WRONG (transient): db_subnet_group_name references the now create_before_destroy
  # subnet group above, so Terraform requires this instance to also become
  # create_before_destroy when it's replaced (dependency graph rule: a resource
  # can't be destroyed while a not-yet-created dependent still needs it). That
  # means Terraform tries to CREATE the new instance before destroying the old
  # one - and identifier was a static, unchanged value, so it collided with the
  # still-live old instance (DBInstanceAlreadyExists). Suffixing it avoids the
  # collision; matches the subnet group's "-v2" naming.
  # identifier          = "${var.project}-${var.environment}-${var.app_name}"
  identifier            = "${var.project}-${var.environment}-${var.app_name}-v2"
  allocated_storage     = var.db_default_settings.allocated_storage
  max_allocated_storage = var.db_default_settings.max_allocated_storage
  engine                = "postgres"
  engine_version        = 14.23
  instance_class        = var.db_default_settings.instance_class
  username              = var.db_default_settings.db_admin_username
  password              = random_password.rds_password.result
  port                  = 5432
  publicly_accessible   = false
  availability_zone     = "us-east-1a"
  db_subnet_group_name  = aws_db_subnet_group.postgres.id
  ca_cert_identifier   = var.db_default_settings.ca_cert_name
  storage_encrypted    = true
  storage_type         = "gp3"
  kms_key_id           = aws_kms_key.env_kms.arn
  skip_final_snapshot  = true
  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  backup_retention_period    = var.db_default_settings.backup_retention_period
  db_name                    = var.db_default_settings.db_name
  auto_minor_version_upgrade = true
  deletion_protection        = false
  copy_tags_to_snapshot      = true

  tags = {
    environment = var.environment
  }
}

resource "random_password" "rds_password" {
  length           = 10
  special          = false
  override_special = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

resource "random_password" "backend_secret_key" {
  length           = 10
  special          = false
  override_special = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

resource "aws_secretsmanager_secret" "db_link" {
  name                    = "db/${aws_db_instance.postgres.identifier}"
  description             = "DB link"
  kms_key_id              = aws_kms_key.env_kms.arn
  recovery_window_in_days = 7
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "dbs_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_link.id
  secret_string = "postgresql://${var.db_default_settings.db_admin_username}:${random_password.rds_password.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "postgres" {
  name        = "${var.project}-${var.environment}-${var.app_name}-v2"
  description = "Subnet group for RDS instance (subnets 5 & 6)"
  subnet_ids = [
    aws_subnet.rds_1.id,
    aws_subnet.rds_2.id
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_kms_key" "env_kms" {
  description             = "KMS key for RDS and Secrets Manager"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.project}-${var.environment}-db"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "env_kms_alias" {
  name          = "alias/${var.project}-${var.environment}-db"
  target_key_id = aws_kms_key.env_kms.id
}