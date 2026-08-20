# The ingress code is placed below the k8s.tf code because the ingress controller needs to be created first before we can create the ingress resource. 
# The ingress resource will create the ALB and we need to wait for it to be created before we can create the route53 record for the subdomain. 
# The ingress resource will also create the ACM certificate for the subdomain and we need to wait for it to be validated before we can create the route53 record for the subdomain.
