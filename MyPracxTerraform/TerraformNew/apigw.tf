resource "aws_api_gateway_rest_api" "app-api" {
  name = "AppAPI"
  description = "Api Gateway for Lambda to DynamdoDB Integration"
}


resource "aws_api_gateway_resource" "app_resource" {
  
  rest_api_id = aws_api_gateway_rest_api.app-api.id
  parent_id = aws_api_gateway_rest_api.app-api.root_resource_id
  path_part = "item"
}

resource "aws_api_gateway_method" "app_method" {
  rest_api_id = aws_api_gateway_rest_api.app-api.id
  resource_id = aws_api_gateway_resource.app_resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
 rest_api_id = aws_api_gateway_rest_api.app-api.id
 resource_id = aws_api_gateway_resource.app_resource.id
 http_method = aws_api_gateway_method.app_method.http_method
 integration_http_method = "POST"
 type = "AWS_PROXY"
 uri = aws_lambda_function.lambda-function.invoke_arn

 depends_on = [aws_lambda_permission.api_gateway_invoke]
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.app-api.execution_arn}/*/*"
}