output "lambda_name" {
  value = aws_lambda_function.reader.function_name
}

output "param_path" {
  value = local.param_path
}

output "db_host_parameter_name" {
  value = aws_ssm_parameter.db_host.name
}

output "api_token_parameter_name" {
  value = aws_ssm_parameter.api_token.name
}

output "kms_key_arn" {
  value = aws_kms_key.ssm.arn
}

output "iam_role_name" {
  value = aws_iam_role.lambda_exec.name
}
