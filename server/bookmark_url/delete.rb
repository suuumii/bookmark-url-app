# require 'httparty'
require 'json'
require "logger"
require "ulid"
require "aws-sdk-dynamodb"
require "bigdecimal"

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::DEBUG)
end

def delete_bookmark(params)
  client = Aws::DynamoDB::Client.new(region: "ap-northeast-1")
  res = client.delete_item(
    key: {
      "user_id" => params["user_id"],
      "bookmark_id" => params["bookmark_id"]
    },
    table_name: ENV.fetch('TABLE_NAME')
  )
  logger.debug(res)
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  params = JSON.parse(event['body'])

  delete_bookmark(params)

  # https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
  {
    statusCode: 200,
    headers: {
      "Content-Type" => "application/json"
    },
    body: JSON.generate({ message: "success" })
  }
end
