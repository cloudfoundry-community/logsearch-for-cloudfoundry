const isObject = (value) => {
  return value instanceof Object && !(value instanceof Array)
}

const ensureKeys = (value, keys) => {
  let key
  while (keys.length) {
    key = keys.shift()
    if (typeof value[key] === 'undefined') {
      value[key] = {}
    }
    value = value[key]
  }
  return value
}

const filterSuggestionQuery = (payload, cached) => {
  // query for /api/kibana/suggestions/values/<index name> endpoints after kibana 7.7
  let boolFilter = payload.boolFilter || []

  boolFilter.push(
    {'bool':
      {'must': [
        { 'terms': { '@cf.space_id': cached.account.spaceIds } },
        { 'terms': { '@cf.org_id': cached.account.orgIds } }
        ]
      }
    }
  )
  payload.boolFilter = boolFilter
  return payload
}

const filterInternalQuery = (payload, cached) => {
  // query for /internal/search/es endpoints after kibana 7.7
  let bool = ensureKeys(payload, ['params', 'body', 'query', 'bool'])

  bool.must = bool.must || []
  // Note: the `must` clause may be an array or an object
  if (isObject(bool.must)) {
    bool.must = [bool.must]
  }
  bool.must.push(
    { 'terms': { '@cf.space_id': cached.account.spaceIds } },
    { 'terms': { '@cf.org_id': cached.account.orgIds } }
  )
  return payload
}

const filterQuery = (payload, cached) => {
  // query for /elasticsearch/_msearch and /elasticsearch/_search prior to Kibana 7.7
  let bool = ensureKeys(payload, ['query', 'bool'])

  bool.must = bool.must || []
  // Note: the `must` clause may be an array or an object
  if (isObject(bool.must)) {
    bool.must = [bool.must]
  }
  bool.must.push(
    { 'terms': { '@cf.space_id': cached.account.spaceIds } },
    { 'terms': { '@cf.org_id': cached.account.orgIds } }
  )
  return payload
}

module.exports = {
  filterQuery,
  filterInternalQuery,
  filterSuggestionQuery
}
