# require 'httparty'
require 'json'
require "logger"
require "ulid"
require "aws-sdk-dynamodb"
require "bigdecimal"

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::DEBUG)
end

def add_bookmark(params)
  client = Aws::DynamoDB::Client.new(region: "ap-northeast-1")
  res = client.put_item(
    item: {
      "user_id" => params["user_id"],
      "bookmark_id" => ULID.generate,
      "bookmark_url" => params["bookmark_url"],
      "title" => params["title"]
    },
    table_name: ENV.fetch('TABLE_NAME')
  )
  logger.debug(res)
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  params = JSON.parse(event['body'])

  add_bookmark(params)

  # https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
  {
    statusCode: 200,
    headers: {
      "Content-Type" => "application/json"
    },
    body: JSON.generate({ message: "success" })
  }
end


if __FILE__ == $PROGRAM_NAME then
  # テスト
  add_bookmark({
    "user_id" => "01JVJ1917D1GDF1SV9CC1HN3JD",
    "bookmark_url" => "https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-dynamodb-table.html",
    "title" => "サンプルAWS::DynamoDB::Table - AWS CloudFormation"
  }) 
end
