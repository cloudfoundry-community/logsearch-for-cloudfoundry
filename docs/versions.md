[<-home page](../README.md)
### Versions

Current Logsearch-for-cloudfoundry version is

| develop |
| ---------------- |

Below you can find a list of dependencies for the current version of Logsearch-for-cloudfoundry.

#### Dependencies & compatibility matrix:

<table>
  <tr>
    <th>Library/tool</th><th>Version</th><th>Distributor</th>
  </tr>
  
  <tr>
    <td>Logsearch (boshrelease)</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/tree/develop">develop</a></td>
    <td>Logsearch</td>
  </tr>

  <tr>
    <td>Elasticsearch</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/develop/config/blobs.yml#L50">2.3.5</a></td>
    <td>Logsearch</td>
  </tr>
  
  <tr>
    <td>Logstash</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/develop/config/blobs.yml#L42">2.3.3</a></td>
    <td>Logsearch</td>
  </tr>
  
  <tr>
    <td rowspan="2">Kibana</td>
    <td><a href="https://github.com/logsearch/logsearch-boshrelease/blob/develop/config/blobs.yml#L46">4.5.4</a> (when deploy as standalone instance)</td>
    <td>Logsearch</td>
  </tr>
  <tr>
    <td><a href="../config/blobs.yml#L2">4.4.2</a> (when deploy as CloudFoundry app)</td>
    <td>Logsearch-for-cloudfoundry</td>
  </tr>
   
  <tr>
    <td>Firehose-to-syslog</td>
    <td><a href="https://github.com/cloudfoundry-community/firehose-to-syslog/tree/2.4.1">2.4.1</a></td>
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
