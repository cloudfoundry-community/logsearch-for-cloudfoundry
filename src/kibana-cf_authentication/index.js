const serverInit = require('./server')

module.exports = (kibana) => {
  return serverInit(kibana)
}
