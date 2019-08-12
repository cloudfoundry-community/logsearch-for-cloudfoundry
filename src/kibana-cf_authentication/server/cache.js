const Catbox = require('catbox')
const RedisClient = require('./catbox-redis')

module.exports = async (server) => {
  const config = server.config()

  // session TTL (auth cache expiration)
  const cacheExpiration = config.get('authentication.session_expiration_ms')
  const cacheSegment = 'sessions'

  // Default to memory cache
  let cache = server.cache({
    segment: cacheSegment,
    expiresIn: cacheExpiration
  })
  // If possible, use redis for cache. Requires REDIS_HOST defined in environment
  if (config.get('authentication.use_redis_sessions')) {
    const policy = { expiresIn: cacheExpiration }
    const options = {
      host: config.get('authentication.redis_host'),
      port: config.get('authentication.redis_port'),
      partition: 'kibana'
    }

    const client = new Catbox.Client(RedisClient, options)
    await client.start()

    cache = new Catbox.Policy(policy, client, cacheSegment)

    return cache
  }

  return cache
}
