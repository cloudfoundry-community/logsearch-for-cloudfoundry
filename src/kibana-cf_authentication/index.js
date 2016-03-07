var Bell = require('bell');
var AuthCookie = require('hapi-auth-cookie');
var Promise = require('bluebird');
var request = Promise.promisify(require('request'));

module.exports = function (kibana) {
  return new kibana.Plugin({
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
    var cloudFoundryApiUri = (process.env.CF_API_URI) ? process.env.CF_API_URI.replace(/\/$/, '') : 'unknown';
    var cfInfoUri = cloudFoundryApiUri + '/v2/info';

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
        authorization_uri: Joi.string().default(cf_info.authorization_endpoint + '/oauth/authorize'),
        logout_uri: Joi.string().default(cf_info.authorization_endpoint + '/logout.do'),
        token_uri: Joi.string().default(cf_info.token_endpoint + '/oauth/token'),
        account_info_uri: Joi.string().default(cf_info.token_endpoint + '/userinfo'),
      }).default();

    }).catch(function (error) {
      console.log('ERROR fetching CF info from ' + cfInfoUri + ' : ' + error);
      throw error;
    });

  },

  /*
  The init method is where all the magic happens. It's essentially the same as the
  register method for a Hapi plugin except it uses promises instead of a callback
  pattern. Just return a promise when you execute an async operation.
  */
  init: function (server, options) {
    var config = server.config();

    server.log(['debug', 'authentication'], JSON.stringify(config.get('authentication')));

    server.register([Bell, AuthCookie], function (err) {

      if (err) {
        server.log(['error', 'authentication'], JSON.stringify(err));
        return;
      }

      server.auth.strategy('uaa-cookie', 'cookie', {
        password: '397hkjhdhshs3uy02hjsdfnlskdfio3', //Password used for encryption
        cookie: 'uaa-auth', // Name of cookie to set
        redirectTo: '/login'
      });

      var uaaProvider = {
        protocol: 'oauth2',
        auth: config.get('authentication.authorization_uri'),
        token: config.get('authentication.token_uri'),
        scope: ['openid', 'oauth.approvals', 'scim.userids', 'cloud_controller.read'],
        profile: function (credentials, params, get, callback) {
          server.log(['debug', 'authentication'],  JSON.stringify({ thecredentials: credentials, theparams: params }));
          get(config.get('authentication.account_info_uri'), null, function (profile) {
            server.log(['debug', 'authentication'], JSON.stringify({ theprofile: profile }));
            credentials.profile = {
              id: profile.id,
              username: profile.username,
              displayName: profile.name,
              email: profile.email,
              raw: profile
            };

            return callback();
          });
        }
      };

      server.auth.strategy('uaa-oauth', 'bell', {
        provider: uaaProvider,
        password: '397hkjhdhshs3uy02hjsdfnlskdfio3', //Password used for encryption
        clientId: config.get('authentication.client_id'),
        clientSecret: config.get('authentication.client_secret'),
        forceHttps: true
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
              reply(request.auth.credentials.profile);
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
        }
    ]);

    }); // end: server.register
  }
  });
};
