[<-home page](../README.md)
### Versions

Current Logsearch-for-cloudfoundry version is

| v1.0.0 |
| ------ |

Below you can find a list of dependencies for the current version of Logsearch-for-cloudfoundry.

#### Dependencies & compatibility matrix:

<table>
  <tr>
    <th>Library/tool</th><th>Version</th><th>Distributor</th>
  </tr>
  
  <tr>
    <td>Logsearch (boshrelease)</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/tree/v203.0.0">v203.0.0</a></td>
    <td>Logsearch</td>
  </tr>

  <tr>
    <td>Elasticsearch</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/v203.0.0/config/blobs.yml#L38">2.2.0</a></td>
    <td>Logsearch</td>
  </tr>
  
  <tr>
    <td>Logstash</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/v203.0.0/config/blobs.yml#L46">2.3.1</a></td>
    <td>Logsearch</td>
  </tr>
  
  <tr>
    <td rowspan="2">Kibana</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/v203.0.0/config/blobs.yml#L42">4.4.0</a> (when deploy as standalone instance)</td>
    <td>Logsearch</td>
  </tr>
  <tr>
    <td><a href="../config/blobs.yml#L2">4.4.2</a> (when deploy as CloudFoundry app)</td>
    <td>Logsearch-for-cloudfoundry</td>
  </tr>
   
  <tr>
    <td>Firehose-to-syslog</td>
    <td><a href="https://github.com/cloudfoundry-community/firehose-to-syslog/tree/2.0.0">2.0.0</a></td>
    <td>Logsearch-for-cloudfoundry</td>
  </tr>
  
  <tr>
    <td rowspan="2">CloudFoundry</td>
    <td><a href="https://github.com/cloudfoundry/cf-release">cf-release</a></td>
    <td>CloudFoundry</td>
  </tr>
  <tr>
    <td><a href="https://github.com/cloudfoundry/diego-release">diego-release</a></td>
    <td>CloudFoundry</td>
  </tr>
</table>

</br>See full list of dependencies in [_Logsearch blobs config_](https://github.com/logsearch/logsearch-boshrelease/blob/develop/config/blobs.yml) and [Logsearch-for-cloudfoundry blobs config](../config/blobs.yml).

</br>[<- prev page](troubleshooting.md) | [next page ->](links.md)
