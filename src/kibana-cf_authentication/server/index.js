const Bell = require('bell') // OAuth2.0 authentication library (see https://github.com/hapijs/bell for lib details)
const AuthCookie = require('hapi-auth-cookie') // auth strategies mechanism

const initConfig = require('./config')
const initCache = require('./cache')
const initUaaProvider = require('./uaa-provider')
const initRoutes = require('./routes')

/*
 --------------------------
 Authentication mechanism: |
 --------------------------
 -- I --
 All calls by default are guarded by `uaa-cookie` strategy.
 The strategy checks the following:
 # 1) If `uaa-auth` cookie is set, then session_id, decoded from it, is verified for existence in the cache.
 If exists, then the user has already been authenticated. The cached entry stores user auth credentials object (OAuth tokens)
 and user account details (name, orgs/spaces).
 # 2) If the cookie is not set, or cache verification fails, then the user has to be authenticated first.
 The user is redirected to /login for authentication.

 -- II --
 /login call is guarded by `uaa-oauth` strategy.
 In this strategy we perform OAuth2 authentication using UAA server. Bell lib (https://github.com/hapijs/bell) is used for implementation.
 Authorization flow:
 1) obtain client authorization code
 2) obtain user token (access token, refresh token etc.)
 3) obtain user profile (delegates to configured provider.profile function)

 provider.profile function is implemented to
 1) obtain user account details, orgs/spaces
 2) store user credentials (OAuth tokens) and account (name, orgs/spaces) details into the cache.
 Key for a cache entry is just a generated uuid given as a session_id for that user session.

 Handler for /login call validates if a user has been authenticated successfully and if so,
 it sets `uaa-auth` cookie with the value of the user session_id.
 */

module.exports = (kibana) => {
  return new kibana.Plugin({
    uiExports: {
      app: {
        title: 'User',
        main: 'plugins/authentication/user',
        icon: 'plugins/authentication/user_icon.png'
      }
    },
    /*
     This will set the name of the plugin and will be used by the server for
     namespacing purposes in the configuration. In Hapi you can expose methods and
     objects to the system via `server.expose()`. Access to these attributes are done
     via `server.plugins.<name>.<attribute>`. See the `elasticsearch` plugin for an
     example of how this is done. If you omit this attribute then the plugin loader
     will try to set it to the name of the parent folder.
     */
    name: 'authentication',

    /*
     This is an array of plugin names this plugin depends on. These are guaranteed
     to load before the init() method for this plugin is executed.
     */
    require: [],

    /*
    This method is executed to create a Joi schema for the plugin.
    The Joi module is passed to every config method and config methods can return promises
    if they need to execute an async operation before setting the defaults. If you're
    returning a promise then you should resolve the promise with the Joi schema.
    */
    config: (Joi) => {
      return initConfig(Joi)
    },
    /*
       The init method is where all the magic happens. It's essentially the same as the
       register method for a Hapi plugin except it uses promises instead of a callback
       pattern. Just return a promise when you execute an async operation.
       */
    async init (server, options) {
      const config = server.config()

      server.log(['debug', 'authentication'], JSON.stringify(config.get('authentication')))

      // If X-Pack is installed it needs to be disabled for Search Guard to run.
      try {
        let xpackSecurityInstalled = false;
        Object.keys(server.plugins).forEach((plugin) => {
          if (plugin.toLowerCase().indexOf('xpack') > -1) {
            xpackSecurityInstalled = true;
          }
        });

        if (xpackSecurityInstalled && config.get('xpack.security.enabled') !== false) {
          // It seems like X-Pack is installed and enabled, so we show an error message and then exit.
          this.status.red("X-Pack Security needs to be disabled for Search Guard to work properly. Please set 'xpack.security.enabled: false' in your kibana.yml");
          return false;
        }
      } catch (error) {
        server.log(['error', 'authentication'], `An error occurred while making sure that X-Pack isn't enabled`)
        return false
      }

      try {
        const cache = await initCache(server)
        const isSecure = config.get('authentication.use_https')

        await server.register([Bell, AuthCookie])
        /* Add `uaa-cookie` authentication startegy.
         In this strategy we validate that
         1) 'uaa-auth' cookie is set in a request,
         2) session_id decoded from the cookie exists in the cache of authenticated sessions
         (the cache contains pairs session_id <- {credentials, account}).

         If the validation fails we reply 'unauthorized' and redirect to /login for user authentication.
         (for the strategy logic see hapi-auth-cookie/lib/index.js authenticate function)
         */

        server.auth.strategy('uaa-cookie', 'cookie', {
          password: config.get('authentication.random_passphrase'), // Password used for encryption
          cookie: 'uaa-auth', // Name of cookie to set
          redirectTo: '/login', // unauthenticated users are redirected to this url

          validateFunc: async (request, session) => {
            let cached
            try {
              cached = await cache.get(session.session_id)
            } catch (error) {
              server.log(['error', 'authentication', 'session:validation'], JSON.stringify(err));
              return { valid: false }
            }

            if (!cached) {
              return { valid: false }
            }
            return { valid: true, credentials: cached.credentials }
          },
          isSecure,
          ttl: config.get('authentication.session_expiration_ms') // session TTL (cookie expiration)
        })

        const uaaProvider = initUaaProvider(server, config, cache)

        /*
          Add `uaa-oauth` authentication startegy.
          Performs OAuth2 authentication using configured authentication provider.
          (see bell/lib/oauth.js exports.v2)
         */
        server.auth.strategy('uaa-oauth', 'bell', {
          provider: uaaProvider,
          password: config.get('authentication.random_passphrase'), // Password used for encryption
          clientId: config.get('authentication.client_id'),
          clientSecret: config.get('authentication.client_secret'),
          forceHttps: isSecure,
          isSecure: isSecure
        })

        server.auth.default('uaa-cookie') // all cals by default are guarded by `uaa-cookie` strategy

        // add routes to server
        server.route(initRoutes(server, config, cache))

        // Redirect _msearch and _search through our own routes so that we can modify the payload
        // This also includes the auto-suggestions for filters.
        server.ext('onRequest', (request, reply) => {
          if (/elasticsearch\/_msearch/.test(request.path) && !request.auth.artifacts) {
            request.setUrl('/_filtered_msearch')
          } else if (/internal\/search\/es/.test(request.path) && !request.auth.artifacts) {
            request.setUrl('/_filtered_internal_search')
          } else if (/api\/kibana\/suggestions\/values/.test(request.path) && !request.auth.artifacts) {
            const match = /api\/kibana\/suggestions\/values\/([^\/]+)/.exec(request.path)
            request.setUrl('/' + match[1] + '/_filtered_suggestions')
          } else {
            const match = /elasticsearch\/([^\/]+)\/_search/.exec(request.path)

            if (match !== null && !request.auth.artifacts) {
              request.setUrl('/' + match[1] + '/_filtered_search')
            }
          }

          return reply.continue
        })
      } catch (error) {
        console.error('server.init.error', error)
      }
    }
  })
}
