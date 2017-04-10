# Firehose-to-syslog TLS syslog endpoint

## Generating the certificate for TLS syslog

Please use [gen-certs.py](https://github.com/RackSec/srslog/blob/master/script/gen-certs.py) for certificate generation. 

```
python gen-certs.py
```

That scripts outputs the public key and private key to standard out.

Deployment                  | Content                                        | Property
--------------------------- | -----------------------------------------------| ------------------------------------------------
Logsearch                   | Public Key                                     | `properties.logstash_ingestor.syslog_tls.ssl_key`
Logsearch                   | Private Key                                    | `properties.logstash_ingestor.syslog_tls.ssl_cert`
Logsearch for Cloud Foundry | PEM containing a private key and a certificate | `properties.syslog.cert_pem`

**Note**: If you generate a self-signed certificate for the TLS Syslog, set the value of `properties.logstash_ingestor.syslog_tls.skip_ssl_validation` to true.
