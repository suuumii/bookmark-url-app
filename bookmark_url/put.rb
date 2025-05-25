# require 'httparty'
require 'json'
require "logger"
require "ulid"
require "aws-sdk-dynamodb"
require "bigdecimal"

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::DEBUG)
end

def update_bookmark(params)
  client = Aws::DynamoDB::Client.new(region: "ap-northeast-1")
  res = client.update_item(
    key: {
      "user_id" => params["user_id"],
      "bookmark_id" => params["bookmark_id"]
    },
    update_expression: 'SET title = :title, bookmark_url = :bookmark_url',
    expression_attribute_values: {
      ':title' => params["title"],
      ':bookmark_url' => params["bookmark_url"]
    },
    table_name: ENV.fetch('TABLE_NAME')
  )
  logger.debug(res)
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  params = JSON.parse(event['body'])

  update_bookmark(params)

  # https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
  {
    statusCode: 200,
    headers: {
      "Content-Type" => "application/json"
    },
    body: JSON.generate({ message: "success" })
  }
end
