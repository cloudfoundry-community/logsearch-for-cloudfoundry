const { filterQuery, filterInternalQuery, filterSuggestionQuery } = require('./helpers')

module.exports = (server, config, cache) => {
  return [
    {
      /* Endpoint for users authentication. Unauthenticated users are redirected to it
       for user authentication (see configuration of `uaa-cookie` strategy).
       Is guarded by `uaa-oauth` strategy which triggers OAuth user authentiction using UAA.
       Sets `uaa-auth` cookie if the user has been authenticated successfully.
       */
      method: 'GET',
      path: '/login',
      config: {
        auth: 'uaa-oauth', // /login is guarded by `uaa-oauth` strategy
        handler: (request, h) => {
          if (request.auth.isAuthenticated) {
            /* Sets uaa-auth cookie with value of user auth session_id.
             (see request.auth.session definition in hapi-auth-cookie/lib/index.js) */
            const session_id = '' + request.auth.credentials.session_id

            request.cookieAuth.set({ session_id })

            return h.redirect('/')
          }
          return h.response().code(401)
        }
      }
    },
    {
      method: 'GET',
      path: '/account',
      config: {
        handler: async (request, h) => {
          let cached

          try {
            if (request.auth && request.auth.credentials && request.auth.credentials.session_id) {
              cached = await cache.get(request.auth.credentials.session_id)
            }
          } catch (error) {
            server.log(['error', 'authentication', 'session:get:account'], JSON.stringify(error))
          }
          return (cached && cached.account && cached.account.profile)
            ? cached.account.profile
            : {}
        }
      }
    },
    {
      method: 'GET',
      path: '/logout',
      config: {
        handler: async (request, h) => {
          try {
            await cache.drop(request.auth.credentials.session_id)
            /* Clears `uaa-auth` cookie.
           (see request.auth.session definition in hapi-auth-cookie/lib/index.js)
           */
            request.cookieAuth.clear()
          } catch (error) {
            server.log(['error', 'authentication', 'session:logout'], JSON.stringify(error))
          }
          /* Redirect to UAA logout. */
          return h.redirect(config.get('authentication.logout_uri'))
        }
      }
    },
    {
      method: 'POST',
      path: '/_filtered_msearch',
      config: {
        payload: {
          parse: false
        },
        validate: { payload: null },
        handler: async (request, h) => {
          const options = {
            method: 'POST',
            url: '/elasticsearch/_msearch',
            artifacts: true
          };
          let cached
          try {
            cached = await cache.get(request.auth.credentials.session_id)

            if (cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1 && !(config.get('authentication.skip_authorization'))) {
              const modifiedPayload = [];
              const lines = request.payload.toString().split('\n')
              const numLines = lines.length;
              for (var i = 0; i < numLines - 1; i += 2) {
                const indexes = lines[i]
                let query = JSON.parse(lines[i + 1])

                query = filterQuery(query, cached)
                modifiedPayload.push(indexes)
                modifiedPayload.push(JSON.stringify(query))
              }
              options.payload = new Buffer(modifiedPayload.join('\n') + '\n')
            } else {
              options.payload = request.payload
            }
          } catch (error) {
            server.log(['error', 'authentication', 'session:get:_filtered_msearch'], JSON.stringify(error))
          } finally {
            options.headers = request.headers

            delete options.headers.host
            delete options.headers['user-agent']
            delete options.headers['accept-encoding']
            options.headers['content-length'] = options.payload.length

            const resp = await server.inject(options)

            const response = h.response()

            response.code(resp.statusCode)
            response.type(resp.headers['content-type'])
            response.passThrough(true)

            return resp.result || resp.payload
          }
        }
      }
    },
    {
      method: 'POST',
      path: '/{index}/_filtered_search',
      config: {
        payload: {
          parse: false
        },
        validate: { payload: null },
        handler: async (request, h) => {
          const options = {
            method: 'POST',
            url: '/elasticsearch/' + request.params.index + '/_search',
            artifacts: true
          }

          let cached
          try {
            cached = await cache.get(request.auth.credentials.session_id)

            if (cached
              && cached.account
              && cached.account.orgs
              && cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1
              && !(config.get('authentication.skip_authorization'))) {
              let payload = JSON.parse(request.payload.toString() || '{}')
              payload = filterQuery(payload, cached)

              options.payload = new Buffer(JSON.stringify(payload))
            } else {
              options.payload = request.payload
            }
          } catch (error) {
            server.log(['error', 'authentication', 'session:get:_filtered_search'], JSON.stringify(error))
          } finally {
            options.headers = request.headers

            delete options.headers.host
            delete options.headers['user-agent']
            delete options.headers['accept-encoding']

            options.headers['content-length'] = (options.payload && options.payload.length)
              ? options.payload.length
              : 0

            const resp = await server.inject(options)

            const response = h.response()

            response.code(resp.statusCode)
            response.type(resp.headers['content-type'])
            response.passThrough(true)

            return resp.result || resp.payload
          }
        }
      }
    },
    {
      method: 'POST',
      path: '/_filtered_internal_search',
      config: {
        payload: {
          parse: false
        },
        validate: { payload: null },
        handler: async (request, h) => {
          const options = {
            method: 'POST',
            url: '/internal/search/es',
            artifacts: true
          }

          let cached
          try {
            cached = await cache.get(request.auth.credentials.session_id)

            if (cached
              && cached.account
              && cached.account.orgs
              && cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1
              && !(config.get('authentication.skip_authorization'))) {
              let payload = JSON.parse(request.payload.toString() || '{}')
              payload = filterInternalQuery(payload, cached)

              options.payload = new Buffer(JSON.stringify(payload))
            } else {
              options.payload = request.payload
            }
          } catch (error) {
            server.log(['error', 'authentication', 'session:get:_filtered_internal_search'], JSON.stringify(error))
          } finally {
            options.headers = request.headers

            delete options.headers.host
            delete options.headers['user-agent']
            delete options.headers['accept-encoding']

            options.headers['content-length'] = (options.payload && options.payload.length)
              ? options.payload.length
              : 0

            const resp = await server.inject(options)

            const response = h.response()

            response.code(resp.statusCode)
            response.type(resp.headers['content-type'])
            response.passThrough(true)

            return resp.result || resp.payload
          }
        }
      }
    },
    {
      method: 'POST',
      path: '/{index}/_filtered_suggestions',
      config: {
        payload: {
          parse: false
        },
        validate: { payload: null },
        handler: async (request, h) => {
          const options = {
            method: 'POST',
            url: '/api/kibana/suggestions/values/' + request.params.index,
            artifacts: true
          };
          let cached
          try {
            cached = await cache.get(request.auth.credentials.session_id)

            if (cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1 && !(config.get('authentication.skip_authorization'))) {
              let payload = JSON.parse(request.payload.toString() || '{}')
              payload = filterSuggestionQuery(payload, cached)
              options.payload = new Buffer(JSON.stringify(payload))
            } else {
              options.payload = request.payload
            }
          } catch (error) {
            server.log(['error', 'authentication', 'session:get:_filtered_suggestions'], JSON.stringify(error))
          } finally {
            options.headers = request.headers

            delete options.headers.host
            delete options.headers['user-agent']
            delete options.headers['accept-encoding']
            options.headers['content-length'] = options.payload.length

            const resp = await server.inject(options)

            const response = h.response()

            if (resp.statusCode > 399) {
              server.log(['error', 'authentication', 'session:get:_filtered_suggestions'], resp.result)
              response.code(200)
              response.type("application/json")
              return JSON.stringify([])
            }

            response.code(resp.statusCode)
            response.type(resp.headers['content-type'])
            response.passThrough(true)

            return resp.result || resp.payload
          }
        }
      }
    }
  ]
}
