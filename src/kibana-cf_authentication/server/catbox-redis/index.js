// Load modules

const Redis = require('redis')
const Hoek = require('hoek')

// Declare internals

const internals = {
  defaults: {
    host: '127.0.0.1',
    port: 6379
  }
}

class Connection {
  constructor (options) {
    Hoek.assert(
      this.constructor === Connection,
      'Redis cache client must be instantiated using new'
    )

    this.settings = Hoek.applyToDefaults(internals.defaults, options)
    this.client = null
    return this
  }

  async start () {
    if (this.client) {
      return
    }

    const client = Redis.createClient(this.settings.port, this.settings.host)

    if (this.settings.password) {
      client.auth(this.settings.password)
    }

    if (this.settings.partition) {
      client.select(this.settings.partition)
    }

    // Listen to errors
    client.on('error', (err) => {
      // Failed to connect
      if (!this.client) {
        client.end()
        // TODO better way - use Boom
        return err
      }
    })
    // Wait for connection
    client.once('connect', () => {
      this.client = client
    })
  }

  stop () {
    if (this.client) {
      this.client.removeAllListeners()
      this.client.quit()
      this.client = null
    }
  }

  isReady () {
    return !!this.client && this.client.connected
  }

  validateSegmentName (name) {
    if (!name) {
      return new Error('Empty string')
    }

    if (name.indexOf('\0') !== -1) {
      return new Error('Includes null character')
    }

    return null
  }

  async get (key) {
    const self = this

    return new Promise((resolve, reject) => {
      if (!self.client) {
        return reject(new Error('Connection not started'))
      }
      this.client.get(self.generateKey(key), (err, result) => {
        if (err) {
          return reject(err)
        }

        if (!result) {
          return resolve(null, null)
        }
        let envelope = null
        try {
          envelope = JSON.parse(result)
        } catch (err) { }     // Handled by validation below

        if (!envelope) {
          return reject(new Error('Bad envelope content'))
        }

        if (!envelope.item || !envelope.stored) {
          return reject(new Error('catbox-redis.set.Incorrect envelope structure'))
        }

        return resolve(envelope)
      })
    })
  }

  async set (key, value, ttl) {
    return new Promise((resolve, reject) => {
      if (!this.client) {
        return reject(new Error('catbox-redis.set.Connection not started'))
      }

      const envelope = {
        item: value,
        stored: Date.now(),
        ttl: ttl
      }

      const cacheKey = this.generateKey(key)

      let stringifiedEnvelope = null

      try {
        stringifiedEnvelope = JSON.stringify(envelope)
      } catch (err) {
        return reject(err)
      }

      this.client.set(cacheKey, stringifiedEnvelope, (err) => {
        if (err) {
          return reject(err)
        }

        const ttlSec = Math.max(1, Math.floor(ttl / 1000))
        // Use 'pexpire' with ttl in Redis 2.6.0
        this.client.expire(cacheKey, ttlSec, (err) => {
          if (err) return reject(err)

          return resolve()
        })
      })
    })
  }

  async drop (key) {
    return new Promise((resolve, reject) => {
      if (!this.client) {
        return reject(new Error('catbox-redis.drop.Connection not started'))
      }

      this.client.del(this.generateKey(key), function (err) {
        if (err) return reject(err)
        return resolve()
      })
    })
  }

  generateKey (key) {
    return `${encodeURIComponent(this.settings.partition)}:${encodeURIComponent(key.segment)}:${encodeURIComponent(key.id)}`
  }
}

module.exports = Connection
