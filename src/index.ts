import { Handler } from 'aws-lambda'

export const handler: Handler = async (event) => {
  console.log('Event: ', event)
  let responseMessage = 'Hello, World!'

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: responseMessage
    })
  }
}
