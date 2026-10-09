resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/devops-3tier-app"
  retention_in_days = 7

  tags = {
    Name = "devops-3tier-logs"
  }
}

# ---------------------------------------------------------
# ECS TASK EXECUTION ROLE
# ---------------------------------------------------------
