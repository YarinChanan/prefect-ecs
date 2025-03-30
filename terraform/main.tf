#Creates an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}


resource "aws_ecs_task_definition" "prefect_task" {
  family                = "prefect-task"
  network_mode          = "awsvpc"
  cpu                   = "1024"
  memory                = "2048"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn    = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "prefect-server"
      image     = var.prefect_ecr_repository_url
      essential = true
      cpu       = 1024
      memory    = 2048
      portMappings = [
        {
          containerPort = 4200
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PREFECT_SERVER_API_HOST", value = "0.0.0.0" }
      ]
      secrets: [
        {
          name: "PREFECT_API_KEY",
          valueFrom: "arn:aws:secretsmanager:eu-central-1:235494809920:secret:prefect_api_key_yarin-pE4FFN"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"     = aws_cloudwatch_log_group.logs_group.name
          "awslogs-region"    = var.region
          "awslogs-stream-prefix" = "prefect"
        }
      }
    }
  ])
}



#Declares an AWS ECS service resource. 
resource "aws_ecs_service" "prefect_service" {
  name            = "prefect-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.prefect_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.prefect_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prefect_target_group.arn
    container_name   = "prefect-server"
    container_port   = 4200
  }

  depends_on = [
        aws_lb_listener.https_listener,
        aws_lb_listener.http_listener
    ]
}


# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow inbound HTTP traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { 
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# ALB
resource "aws_lb" "alb" {
  depends_on         = [aws_security_group.alb_sg]
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
}



# ALB Target Group
resource "aws_lb_target_group" "prefect_target_group" {
  name        = "prefect-target-group"
  port        = 4200
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path     = "/health" # Or "/" or whatever your health check path is
    port     = "4200"
    protocol = "HTTP"
    matcher  = "200"
  }
}


# ALB Listener
resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port              = "443"
    protocol          = "HTTPS"
    certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.prefect_target_group.arn
    }
    depends_on = [aws_acm_certificate_validation.cert_validation]
}


resource "aws_lb_listener" "http_listener" {
    load_balancer_arn = aws_lb.alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type = "redirect"
        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}



# Security group for ECS service
resource "aws_security_group" "prefect_sg" {
  name        = "prefect_sg"
  description = "Allow ECS traffic for Prefect service"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 4200
    to_port         = 4200
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound access to the internet
  }
}




# VPC Endpoint for ECR Docker (for pulling images)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.eu-central-1.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids = module.vpc.private_subnets

  security_group_ids = [aws_security_group.prefect_sg.id] # Use the security group attached to the ECS tasks
}

# VPC Endpoint for ECR API (for ECR API calls)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.eu-central-1.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids = module.vpc.private_subnets

  security_group_ids = [aws_security_group.prefect_sg.id] # Use the security group attached to the ECS tasks
}


