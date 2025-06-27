# terraform/ecr.tf
resource "aws_ecr_repository" "craftista_repos" {
  for_each = toset([
    "craftista/frontend",
    "craftista/catalogue", 
    "craftista/voting",
    "craftista/recommendation"
  ])
  
  name                 = each.value
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  lifecycle_policy {
    policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 10 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }
  
  tags = {
    Name        = each.value
    Environment = var.environment
    Project     = "craftista"
  }
}

# Outputs para usar en otros lugares
output "ecr_repositories" {
  value = {
    for k, v in aws_ecr_repository.craftista_repos : k => {
      repository_url = v.repository_url
      registry_id    = v.registry_id
    }
  }
}

# IAM role para Argo Image Updater
resource "aws_iam_role" "argo_image_updater" {
  name = "argo-image-updater-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:argocd:argocd-image-updater"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "argo_image_updater_ecr" {
  name        = "ArgoImageUpdaterECRPolicy"
  description = "IAM policy for Argo Image Updater to access ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "argo_image_updater_ecr" {
  role       = aws_iam_role.argo_image_updater.name
  policy_arn = aws_iam_policy.argo_image_updater_ecr.arn
}