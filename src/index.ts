import { APIGatewayEvent, Handler } from 'aws-lambda'

export const httpHandler: Handler<APIGatewayEvent> = async (event) => {
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

export const cronHandler: Handler<string> = async (payload) => {
  const name = payload

  console.log(`Hello, ${name}!`)
}
