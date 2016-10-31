var Bell = require('bell');
var AuthCookie = require('hapi-auth-cookie');
var Promise = require('bluebird');
var request = Promise.promisify(require('request'));
var uuid = require('uuid');

module.exports = function (kibana) {
  return new kibana.Plugin({
  
  uiExports: {
    app: {
      title: 'User',
      main: 'plugins/authentication/user',
      icon: 'plugins/authentication/user_icon.png',

      autoload: [].concat(kibana.autoload.styles, 'ui/chrome', 'angular')
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
  config: function (Joi) {
    var client_id = (process.env.KIBANA_OAUTH2_CLIENT_ID) ? process.env.KIBANA_OAUTH2_CLIENT_ID : 'client_id';
    var client_secret = (process.env.KIBANA_OAUTH2_CLIENT_SECRET) ? process.env.KIBANA_OAUTH2_CLIENT_SECRET : 'client_secret';
    var skip_ssl_validation = (process.env.SKIP_SSL_VALIDATION) ? (process.env.SKIP_SSL_VALIDATION.toLowerCase() === 'true') : false;
    var cf_system_org = (process.env.CF_SYSTEM_ORG) ? process.env.CF_SYSTEM_ORG : 'system';
    var cloudFoundryApiUri = (process.env.CF_API_URI) ? process.env.CF_API_URI.replace(/\/$/, '') : 'unknown';
    var use_redis_sessions = (process.env.REDIS_HOST) ? true : false;
    var redis_host = (process.env.REDIS_HOST) ? process.env.REDIS_HOST : '127.0.0.1';
    var redis_port = (process.env.REDIS_PORT) ? process.env.REDIS_PORT : '6379';
    var cfInfoUri = cloudFoundryApiUri + '/v2/info';
    var sessionExpirationMs = (process.env.SESSION_EXPIRATION_MS) ? process.env.SESSION_EXPIRATION_MS : 12 * 60 * 60 * 1000; // 12 hours by default

    if (skip_ssl_validation) {
      process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
    }

    //Fetch location of login server, then set config
    return request(cfInfoUri).spread(function (response, body) {

      var cf_info = JSON.parse(body);

      return Joi.object({
        enabled: Joi.boolean().default(true),
        client_id: Joi.string().default(client_id),
        client_secret: Joi.string().default(client_secret),
        skip_ssl_validation: Joi.boolean().default(skip_ssl_validation),
        cf_system_org: Joi.string().default(cf_system_org),
        authorization_uri: Joi.string().default(cf_info.authorization_endpoint + '/oauth/authorize'),
        logout_uri: Joi.string().default(cf_info.authorization_endpoint + '/logout.do'),
        token_uri: Joi.string().default(cf_info.token_endpoint + '/oauth/token'),
        account_info_uri: Joi.string().default(cf_info.token_endpoint + '/userinfo'),
        organizations_uri: Joi.string().default(cloudFoundryApiUri + '/v2/organizations'),
        spaces_uri: Joi.string().default(cloudFoundryApiUri + '/v2/spaces'),
        random_passphrase: Joi.string().default(client_secret.split('').reverse().join('')),
        use_redis_sessions: Joi.boolean().default(use_redis_sessions),
        redis_host: Joi.string().default(redis_host),
        redis_port: Joi.string().default(redis_port),
        session_expiration_ms: Joi.number().integer().default(sessionExpirationMs)
      }).default();

    }).catch(function (error) {
      console.log('ERROR fetching CF info from ' + cfInfoUri + ' : ' + error);
      return Joi.object({
        enabled: Joi.boolean().default(true)
      }).default();
    });

  },

  /*
  The init method is where all the magic happens. It's essentially the same as the
  register method for a Hapi plugin except it uses promises instead of a callback
  pattern. Just return a promise when you execute an async operation.
  */
  init: function (server, options) {
    var config = server.config();
    var isSecure = (process.env.USE_HTTPS) ? process.env.USE_HTTPS : true;

    server.log(['debug', 'authentication'], JSON.stringify(config.get('authentication')));

    server.register([Bell, AuthCookie], function (err) {

      if (err) {
        server.log(['error', 'authentication'], JSON.stringify(err));
        return;
      }

      // Setup the cache for session data
      var cache_expiration = config.get('authentication.session_expiration_ms'); // session TTL (auth cache expiration)
      var cache_segment = 'sessions';
      // Default to memory cache
      var cache = server.cache({
        segment: cache_segment,
        expiresIn: cache_expiration
      });
      // If possible, use redis for cache. Requires REDIS_HOST defined in environment
      if (config.get('authentication.use_redis_sessions')) {
        var policy = { expiresIn: cache_expiration };
        var options = {
          host: config.get('authentication.redis_host'),
          port: config.get('authentication.redis_port'),
          partition: 'kibana'
        };
        var Catbox = require('catbox');
        var client = new Catbox.Client(require('catbox-redis'), options);
        client.start(function(err) {
          if (err) {
            server.log(['err', 'cache', 'redis'], err);
          }
          cache = new Catbox.Policy(policy, client, cache_segment);
        });
      }

      server.auth.strategy('uaa-cookie', 'cookie', {
        password: config.get('authentication.random_passphrase'), //Password used for encryption
        cookie: 'uaa-auth', // Name of cookie to set
        redirectTo: '/login',
        validateFunc: function(request, session, callback) {
          cache.get(session.session_id, function(err, cached) {
            if (err) {
              server.log(['error', 'authentication', 'session:validation'], JSON.stringify(err));
              return callback(err, false);
            }
            if (!cached) {
              return callback(null, false);
            }
            return callback(null, true, cached.credentials);
          });
        },
        isSecure: isSecure,
        ttl: config.get('authentication.session_expiration_ms') // session TTL (cookie expiration)
      });

      var uaaProvider = {
        protocol: 'oauth2',
        auth: config.get('authentication.authorization_uri'),
        token: config.get('authentication.token_uri'),
        scope: ['openid', 'oauth.approvals', 'scim.userids', 'cloud_controller.read'],
        profile: function (credentials, params, get, callback) {
          server.log(['debug', 'authentication'],  JSON.stringify({ thecredentials: credentials, theparams: params }));
          var account = {};
          credentials.session_id = uuid.v1();
          get(config.get('authentication.account_info_uri'), null, function (profile) {
            server.log(['debug', 'authentication'], JSON.stringify({ theprofile: profile }));
            account.profile = {
              id: profile.id,
              username: profile.username,
              displayName: profile.name,
              email: profile.email,
              raw: profile
            };

            get(config.get('authentication.organizations_uri'), null, function(orgs) {
              server.log(['debug', 'authentication', 'orgs'], JSON.stringify(orgs));
              account.orgIds = orgs.resources.map(function(resource) { return resource.metadata.guid; });
              account.orgs = orgs.resources.map(function(resource) { return resource.entity.name; });

              get(config.get('authentication.spaces_uri'), null, function(spaces) {
                server.log(['debug', 'authentication', 'spaces'], JSON.stringify(spaces));
                account.spaceIds = spaces.resources.map(function(resource) { return resource.metadata.guid; });
                account.spaces = spaces.resources.map(function(resource) { return resource.entity.name; });
                cache.set(credentials.session_id, {credentials: credentials, account: account}, 0, function(err) {
                  if (err) {
                    server.log(['error', 'authentication', 'session:set'], JSON.stringify(err));
                  }
                  return callback();
                });
              });
            });
          });
        }
      };

      server.auth.strategy('uaa-oauth', 'bell', {
        provider: uaaProvider,
        password: config.get('authentication.random_passphrase'), //Password used for encryption
        clientId: config.get('authentication.client_id'),
        clientSecret: config.get('authentication.client_secret'),
        forceHttps: isSecure,
        isSecure: isSecure
      });

      server.auth.default('uaa-cookie');

      server.route([{
          method: 'GET',
          path: '/login',
          config: {
            auth: 'uaa-oauth',
            handler: function (request, reply) {
              if (request.auth.isAuthenticated) {
                request.auth.session.set(request.auth.credentials);
                return reply.redirect('/');
              }
              reply('Not logged in...').code(401);
            }
          }
        }, {
          method: 'GET',
          path: '/account',
          config: {
            handler: function (request, reply) {
              cache.get(request.auth.credentials.session_id, function(err, cached) {
                if (err) {
                  server.log(['error', 'authentication', 'session:get:account'], JSON.stringify(err));
                }
                reply(cached.account.profile);
              });
            }
          }
        }, {
          method: 'GET',
          path: '/logout',
          config: {
            auth: false,
            handler: function (request, reply) {
              request.auth.session.clear();
              reply.redirect(config.get('authentication.logout_uri'));
            }
          }
        }, {
          method: 'POST',
          path: '/_filtered_msearch',
          config: {
            payload: {
              parse: false
            },
            handler: function(request, reply) {
              var options = {
                method: 'POST',
                url: '/elasticsearch/_msearch',
                artifacts: true
              };
              cache.get(request.auth.credentials.session_id, function(err, cached) {
                if (err) {
                  server.log(['error', 'authentication', 'session:get:_filtered_msearch'], JSON.stringify(err));
                }
                if (cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1) {
                  var modified_payload = [];
                  var lines = request.payload.toString().split('\n');
                  var num_lines = lines.length;
                  for (var i = 0; i < num_lines - 1; i+=2) {
                    var indexes = lines[i];
                    var query = JSON.parse(lines[i+1]);
                    query = filterQuery(query, cached);
                    modified_payload.push(indexes);
                    modified_payload.push(JSON.stringify(query));
                  }
                  options.payload = new Buffer(modified_payload.join('\n') + '\n');
                } else {
                  options.payload = request.payload;
                }
                options.headers = request.headers;
                delete options.headers.host;
                delete options.headers['user-agent'];
                delete options.headers['accept-encoding'];
                options.headers['content-length'] = options.payload.length;
                server.inject(options, (resp) => {
                  reply(resp.result || resp.payload)
                    .code(resp.statusCode)
                    .type(resp.headers['content-type'])
                    .passThrough(true);
                });
              });
            }
          }
        }, {
          method: 'POST',
          path: '/{index}/_filtered_search',
          config: {
            payload: {
              parse: false
            },
            handler: function(request, reply) {
              var options = {
                method: 'POST',
                url: '/elasticsearch/' + request.params.index + '/_search',
                artifacts: true
              };
              cache.get(request.auth.credentials.session_id, function(err, cached) {
                if (err) {
                  server.log(['error', 'authentication', 'session:get:_filtered_search'], JSON.stringify(err));
                }
                if (cached.account.orgs.indexOf(config.get('authentication.cf_system_org')) === -1) {
                  var payload = JSON.parse(request.payload.toString() || '{}');
                  payload = filterQuery(payload, cached);
                  options.payload = new Buffer(JSON.stringify(payload));
                } else {
                  options.payload = request.payload;
                }
                options.headers = request.headers;
                delete options.headers.host;
                delete options.headers['user-agent'];
                delete options.headers['accept-encoding'];
                options.headers['content-length'] = options.payload.length;
                server.inject(options, (resp) => {
                  reply(resp.result || resp.payload)
                    .code(resp.statusCode)
                    .type(resp.headers['content-type'])
                    .passThrough(true);
                });
              });
            }
          }
        }
      ]);

    }); // end: server.register

    // Redirect _msearch and _search through our own route so we can modify the payload
    server.ext('onRequest', function (request, reply) {
      if (/elasticsearch\/_msearch/.test(request.path) && !request.auth.artifacts) {
        request.setUrl('/_filtered_msearch');
      } else {
        var match = /elasticsearch\/([^\/]+)\/_search/.exec(request.path);
        if (match !== null && !request.auth.artifacts) {
          request.setUrl('/' + match[1] + '/_filtered_search');
        }
      }
      return reply.continue();

    }); // end server.ext('onRequest')

  }

  });
};

function filterQuery(payload, cached) {
  var bool = ensureKeys(payload, ['query', 'filtered', 'filter', 'bool']);
  bool.must = bool.must || [];
  // Note: the `must` clause may be an array or an object
  if (isObject(bool.must)) {
    bool.must = [bool.must];
  }
  bool.must.push(
    {'terms': {'@cf.space_id': cached.account.spaceIds}},
    {'terms': {'@cf.org_id': cached.account.orgIds}}
  );
  return payload;
}

function ensureKeys(value, keys) {
  var key;
  while (keys.length) {
    key = keys.shift();
    if (typeof value[key] === 'undefined') {
      value[key] = {};
    }
    value = value[key];
  }
  return value;
}

function isObject(value) {
  return value instanceof Object && !(value instanceof Array);
}
