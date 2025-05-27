require 'json'
require 'logger'
require 'aws-sdk-dynamodb'

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::DEBUG)
end

def get_bookmark(user_id)
  client = Aws::DynamoDB::Client.new(region: 'ap-northeast-1')
  
  # クエリを実行してブックマークを取得
  result = client.query(
    table_name: ENV.fetch('TABLE_NAME'),
    key_condition_expression: 'user_id = :user_id',
    expression_attribute_values: {
      ':user_id' => user_id
    }
  )

  result.items
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  user_id = event['queryStringParameters']['user_id']

  bookmark = get_bookmark(user_id)

  {
    statusCode: 200,
    headers: {
      "Content-Type" => "application/json"
    },
    body: JSON.generate(bookmark)
  }
end
