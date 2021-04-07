const util = require('util')
const request = util.promisify(require('request'))
const randomstring = require('randomstring')

module.exports = async (Joi) => {
  const useHttps = (process.env.USE_HTTPS)
    ? (process.env.USE_HTTPS.toLowerCase() !== 'false')
    : true

  const clientId = (process.env.KIBANA_OAUTH2_CLIENT_ID)
    ? process.env.KIBANA_OAUTH2_CLIENT_ID
    : 'client_id'

  const clientSecret = (process.env.KIBANA_OAUTH2_CLIENT_SECRET)
    ? process.env.KIBANA_OAUTH2_CLIENT_SECRET
    : 'client_secret'

  const skipSslValidation = (process.env.SKIP_SSL_VALIDATION)
    ? (process.env.SKIP_SSL_VALIDATION.toLowerCase() === 'true')
    : false

  const cfSystemOrg = (process.env.CF_SYSTEM_ORG) ? process.env.CF_SYSTEM_ORG : 'system'

  if (!process.env.CF_API_URI) {
    throw new Error(`config.ERROR system_domain is missing in kibana-auth-plugin.yml`);
  }

  const cloudFoundryApiUri = process.env.CF_API_URI.replace(/\/$/, "");

  const logoutRedirectUri = (process.env.KIBANA_DOMAIN)
    ? ((useHttps)
      ? 'https://' : 'http://') + (process.env.KIBANA_DOMAIN ? process.env.KIBANA_DOMAIN : 'localhost:5601') + '/login' : ''

  const useRedisSessions = (process.env.REDIS_HOST) ? true : false
  const redisHost = (process.env.REDIS_HOST) ? process.env.REDIS_HOST : '127.0.0.1'
  const redisPort = (process.env.REDIS_PORT) ? process.env.REDIS_PORT : '6379'
  const cfInfoUri = cloudFoundryApiUri + '/v2/info'
  const sessionExpirationMs = (process.env.SESSION_EXPIRATION_MS)
    ? process.env.SESSION_EXPIRATION_MS
    : 12 * 60 * 60 * 1000 // 12 hours by default
  const randomString = process.env.SESSION_KEY || randomstring.generate(40)
  const skipAuthorization = process.env.SKIP_AUTHORIZATION

  if (skipSslValidation) {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'
  }
  try {
    // Fetch location of login server, then set config
    const response = await request(cfInfoUri)

    const cfInfo = JSON.parse(response.body)
    const result = Joi.object({
      enabled: Joi.boolean().default(true),
      client_id: Joi.string().default(clientId),
      client_secret: Joi.string().default(clientSecret),
      skip_ssl_validation: Joi.boolean().default(skipSslValidation),
      cf_system_org: Joi.string().default(cfSystemOrg),
      authorization_uri: Joi.string().default(cfInfo.authorization_endpoint + '/oauth/authorize'),
      logout_uri: Joi.string().default(cfInfo.authorization_endpoint + '/logout.do' +
        /*
          Set 'redirect' parameter
          if logout_redirect_uri property is set to get back to Kibana app after logout.
          (note that redirects after logout
          should be also enabled
          in UAA - e.g. https://github.com/cloudfoundry/uaa/blob/3.9.3/uaa/src/main/resources/login.yml#L38-L45)
        */
        ((logoutRedirectUri !== '') ? '?redirect=' + logoutRedirectUri : '')),
      token_uri: Joi.string().default(cfInfo.token_endpoint + '/oauth/token'),
      account_info_uri: Joi.string().default(cfInfo.token_endpoint + '/userinfo'),
      organizations_uri: Joi.string().default(cloudFoundryApiUri + '/v2/organizations'),
      spaces_uri: Joi.string().default(cloudFoundryApiUri + '/v2/spaces'),
      random_passphrase: Joi.string().default(randomString),
      use_redis_sessions: Joi.boolean().default(useRedisSessions),
      redis_host: Joi.string().default(redisHost),
      redis_port: Joi.string().default(redisPort),
      session_expiration_ms: Joi.number().integer().default(sessionExpirationMs),
      use_https: Joi.boolean().default(useHttps),
      skip_authorization: Joi.boolean().default(skipAuthorization)
    }).default()

    return result
  } catch (error) {
    let message = `config.ERROR fetching CF info from "${cfInfoUri}". `;

    message +=
      error.message === "self signed certificate"
        ? "Self signed certificate detected. Please set kibana-auth.cloudfoundry.skip_ssl_validation=true in kibana-auth-plugin.yml if this is desired behavior"
        : error.message;

    throw new Error(message);
  }
}
