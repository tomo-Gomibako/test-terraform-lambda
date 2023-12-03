import { APIGatewayEvent, Handler } from 'aws-lambda'

export const handler: Handler<APIGatewayEvent> = async (event) => {
  const name = event.queryStringParameters?.name

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: 'Hello' + (name ? `, ${name}` : '')
    })
  }
}
