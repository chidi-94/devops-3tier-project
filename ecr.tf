resource "aws_ecr_repository" "app" {
  name                 = "devops-3tier-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devops-3tier-app"
  }
}
# ---------------------------------------------------------
# APPLICATION LOAD BALANCER
# ---------------------------------------------------------
