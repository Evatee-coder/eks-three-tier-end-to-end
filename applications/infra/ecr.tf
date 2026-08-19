
resource "aws_ecr_repository" "frontend" {
    name = "${var.app_name}-frontend"
    force_delete = true    # ✅ allows deletion even if images exist
    image_tag_mutability = "MUTABLE"

    tags = {
        Name = "frontend-repo"
    }
}

resource "aws_ecr_repository" "backend" {
    name = "${var.app_name}-backend"
    force_delete = true    # ✅ allows deletion even if images exist
    image_tag_mutability = "MUTABLE"

    tags = {
        Name = "backend-repo"
    }
}

output "frontend_repository_url" {
    value = aws_ecr_repository.frontend.repository_url
    description = "The URL of the frontend ECR repository. Use this URL to push your frontend Docker images."
}

output "backend_repository_url" {
    value = aws_ecr_repository.backend.repository_url
    description = "The URL of the backend ECR repository. Use this URL to push your backend Docker images."
}
