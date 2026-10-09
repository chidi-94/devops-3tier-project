resource "aws_ecs_cluster" "app" {
  name = "devops-3tier-cluster"

  tags = {
    Name = "devops-3tier-cluster"
  }
}

# ---------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ---------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "devops-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "devops-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------
# ECS TASK DEFINITION
# ---------------------------------------------------------

resource "aws_ecs_task_definition" "app" {
  family                   = "devops-3tier-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "devops-3tier-app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_NAME"
          value = "devopsdb"
        },
        {
          name  = "DB_USER"
          value = "devopsadmin"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = "eu-north-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "devops-3tier-task-definition"
  }
}

# ---------------------------------------------------------
# ECS SERVICE
# ---------------------------------------------------------

resource "aws_ecs_service" "app" {
  name            = "devops-3tier-service"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "devops-3tier-app"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.app,
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name = "devops-3tier-service"
  }
}

# ---------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------
