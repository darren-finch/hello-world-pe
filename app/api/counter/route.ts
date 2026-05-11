// app/api/counter/route.ts
import Redis from 'ioredis'

const redis = new Redis(process.env.REDIS_URL!)

export async function GET() {
  const count = await redis.get('counter') ?? '0'
  return Response.json({ count: parseInt(count) })
}

export async function POST() {
  const count = await redis.incr('counter')
  return Response.json({ count })
}