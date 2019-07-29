const uuid = require('uuid')

module.exports = (server, config, cache) => {
  const uaaProvider = {
    protocol: 'oauth2',
    auth: config.get('authentication.authorization_uri'),
    token: config.get('authentication.token_uri'),
    scope: ['openid', 'oauth.approvals', 'scim.userids', 'cloud_controller.read'],
    /*
      Function for obtaining user profile
      (is called after obtaining user access token in bell/lib/oauth.js v2 function).
      Here we get user account details (profile, orgs/spaces)
      and store it and user credentials (Oauth tokens) in the cache.
      We use generated session_id as a key when storing user data in the cache.
     */
    profile: async (credentials, params, get) => {
      server.log(
        ['debug', 'authentication'],
        JSON.stringify({ credentials, params })
      )

      const account = {}

      // generate user session_id, set it to auth credentials
      credentials.session_id = uuid.v1()

      try {
        const profile = await get(config.get('authentication.account_info_uri'))

        server.log(['debug', 'authentication'], JSON.stringify({ profile }))

        account.profile = {
          id: profile.id,
          username: profile.username,
          displayName: profile.name,
          email: profile.email,
          raw: profile
        }

        // get user orgs
        const orgs = await get(config.get('authentication.organizations_uri'))

        server.log(['debug', 'authentication', 'orgs'], JSON.stringify(orgs))

        account.orgIds = orgs.resources.map((resource) => {
          return resource.metadata.guid
        })
        account.orgs = orgs.resources.map((resource) => {
          return resource.entity.name
        })

        // get user spaces
        const spaces = await get(config.get('authentication.spaces_uri'))

        server.log(['debug', 'authentication', 'spaces'], JSON.stringify(spaces))

        account.spaceIds = spaces.resources.map((resource) => {
          return resource.metadata.guid
        })

        account.spaces = spaces.resources.map((resource) => {
          return resource.entity.name
        })

        // store user data in the cache
        await cache.set(credentials.session_id, { credentials, account }, 0)
      } catch (error) {
        server.log(['error', 'authentication', 'session:set'], JSON.stringify(error))
      }
    }
  }

  return uaaProvider
}
