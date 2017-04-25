# Changelog

## unreleased
### Changed
- Build smoke test index using go templates

## v203.0.0
### Changed
- Create properties mappings for static fields to define their types (https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry/issues/168)

## v202.0.0
### Changed
- Make prefix of index pattern in ES settings/mappings configurable
- Get rid of HttpStart, HttpStop events processing
- Fix RTR parsing
- Use uaa\_admin\_client\_id instead of hardcode when acquire token
- Fix infinite redirect loop when uaa-oauth cookie > 4K
- Better documentation
