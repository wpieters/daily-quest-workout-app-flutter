output "api_url" {
  value = trimsuffix(aws_lambda_function_url.api.function_url, "/")
}

output "table_name" {
  value = aws_dynamodb_table.subscriptions.name
}
