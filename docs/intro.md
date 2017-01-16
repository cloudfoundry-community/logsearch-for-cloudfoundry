[<-home page](../README.md)
### Intro

Before starting using Logsearch-for-cloudfoundry you should get familiar with several base concepts and tools:

#### ELK

The ELK Stack is a collection of three open-source products — [_Elasticsearch_](https://www.elastic.co/products/elasticsearch), [_Logstash_](https://www.elastic.co/products/logstash), and [_Kibana_](https://www.elastic.co/products/kibana) — from [_Elastic_](https://www.elastic.co/). 
Elasticsearch is a NoSQL database based on the Lucene search engine. Logstash is a pipeline tool that accepts inputs from various sources, performs different transformations, and exports the data to various targets. Kibana is a visualization layer that works on top of Elasticsearch.
Together, these three products are known as ELK stack and most commonly used in __log analysis__. Logstash collects and parses logs, Elasticsearch indexes and stores them and then Kibana presents the data in a useful UI.

#### Logsearch

[_Logsearch_](http://www.logsearch.io/) is an open-source project that can be used to build and operate your own __log analysis cluster in the cloud__.
It provides [_boshrelease_](https://github.com/logsearch/logsearch-boshrelease) of a scalable ELK cluster for your own [_BOSH_](http://bosh.io/)-managed infrastructure. The cluster is built using standard ELK stack with considering cloud specifics. It can be used as a standalone deployment or extended with add-ons that fulfills your goals.

#### Logsearch-for-cloudfoundry

Logsearch-for-cloudfoundry is a BOSH-release __add-on for Logsearch__. It extends Logsearch with functionality of retrieving, parsing, indexing and visualizing logs from [_CloudFoundry_](https://github.com/cloudfoundry) platform. Read about [features](features.md) it adds to Logsearch in more detail.

</br>[next page ->](features.md)
