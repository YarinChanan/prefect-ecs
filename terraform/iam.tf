# Creates an IAM role. principal allowed to assume this role is the ECS Tasks service.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# Attaches an IAM policy to the ecs_task_execution_role
# This policy provides the necessary permissions for ECS tasks to register with the ECS control plane and to perform actions like pulling Docker images from ECR.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Creates a custom IAM policy.
resource "aws_iam_policy" "ecs_logging_policy" {
  name        = "ecs_logging_policy"
  description = "Allows ECS tasks to send logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

# Attaches the custom ecs_logging_policy to the ecs_task_execution_role
resource "aws_iam_role_policy_attachment" "ecs_logging_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_logging_policy.arn
}

# Attaches the AmazonEC2ContainerRegistryReadOnly policy to the ecs_task_execution_role
resource "aws_iam_role_policy_attachment" "ecs_ecr_pull_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}




#Allows ECS tasks to retrieve secrets from Secrets Manager
resource "aws_iam_policy" "ecs_task_secrets_policy" {
  name        = "ecs-task-secrets-policy"
  description = "Policy to allow ECS tasks to retrieve secrets from Secrets Manager"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue"
        Effect = "Allow"
        Resource = "arn:aws:secretsmanager:eu-central-1:235494809920:secret:prefect_api_key_yarin-pE4FFN"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_secrets_policy.arn
}