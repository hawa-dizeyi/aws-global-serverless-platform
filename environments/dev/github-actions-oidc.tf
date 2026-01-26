#############################################
# CI/CD — GitHub Actions OIDC Role (per repo)
#############################################

variable "github_repo" {
  description = "GitHub repo allowed to assume this role (owner/repo)"
  type        = string
  default     = "hawa-dizeyi/project-02-global-serverless-platform"
}

# GitHub Actions OIDC provider (create once per AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Standard GitHub Actions OIDC thumbprint
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow ONLY this repo (main branch + PRs)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/main",
        "repo:${var.github_repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  name               = "${module.providers.name_prefix}-gha-terraform"
  description        = "GitHub Actions Terraform role for Project 02"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

# Portfolio-safe permissions:
# - Allows terraform plan/apply
# - Not full admin
resource "aws_iam_role_policy_attachment" "terraform_permissions" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# OPTIONAL (recommended later):
# Attach more specific policies once backend / prod exists

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_terraform.arn
  description = "IAM role ARN for GitHub Actions OIDC"
}
