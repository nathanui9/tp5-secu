locals {
  name       = "${var.project}-${var.name_suffix}"
  param_path = "/tp5/app/"
  tags = {
    Project     = var.project
    TP          = "TP5"
    Owner       = "students"
    Environment = "tp5"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =========================
# KMS - chiffrement du secret
# =========================
resource "aws_kms_key" "ssm" {
  description             = "KMS key TP5 SecureString"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.tags
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${local.name}-ssm"
  target_key_id = aws_kms_key.ssm.key_id
}

# =========================
# SSM Parameter Store
# =========================
resource "aws_ssm_parameter" "db_host" {
  name  = "${local.param_path}DB_HOST"
  type  = "String"
  value = var.db_host
  tags  = local.tags
}

resource "aws_ssm_parameter" "api_token" {
  name   = "${local.param_path}API_TOKEN"
  type   = "SecureString"
  value  = var.api_token
  key_id = aws_kms_key.ssm.arn
  tags   = local.tags
}

# =========================
# Zipper Lambda
# =========================
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# =========================
# IAM - rôle Lambda
# =========================
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${local.name}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ssm_read_path" {
  statement {
    sid    = "ReadOnlyTp5Path"
    effect = "Allow"
    actions = [
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${local.param_path}*"
    ]
  }
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "${local.name}-ssm-read"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.ssm_read_path.json
}

# =========================
# CloudWatch Logs 
# =========================
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name}-ssm-reader"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# =========================
# Lambda - lecture des paramètres
# =========================
resource "aws_lambda_function" "reader" {
  function_name = "${local.name}-ssm-reader"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 10

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      PARAM_PATH = local.param_path
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = local.tags
}
