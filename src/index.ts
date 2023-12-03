import { CloudEvent, cloudEvent, http } from '@google-cloud/functions-framework'

http('helloHttp', (req, res) => {
  const name = req.query.name?.toString()

  res.send('Hello' + (name ? `, ${name}` : ''))
})

type PubSubEventData = {
  message: {
    data: string
  }
}

cloudEvent('helloPubSub', (cloudEvent: CloudEvent<PubSubEventData>) => {
  const base64name = cloudEvent.data?.message.data

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World'

  console.log(`Hello, ${name}!`)
})
