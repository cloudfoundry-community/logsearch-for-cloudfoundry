package logsearchForCloudFoundry;

import static org.junit.Assert.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import org.junit.Test;

public class ElasticsearchQueryModifierTests {

	@Test
	public void shouldReplaceSingleIndexInMQuery() {
		TenantAliasCreator mockTenantAliasCreator = mock(TenantAliasCreator.class);
		when(mockTenantAliasCreator.fetchTenantAlias("logstash-*")).thenReturn("tenantName-logstash-*");
		
		ElasticsearchQueryModifier m = new ElasticsearchQueryModifier(mockTenantAliasCreator);
		String originalQuery = "{\"index\":\"logstash-*\",\"ignore_unavailable\":true}\n" + 
				"{\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041572}}}],\"must_not\":[]}}}},\"size\":500,\"sort\":{\"@timestamp\":\"desc\"},\"fields\":[\"*\",\"_source\"],\"script_fields\":{},\"fielddata_fields\":[\"@timestamp\",\"received_at\"]}\n";
		String modifiedQuery = m.ReplaceIndicesWithTenantAliases(originalQuery);
		
		assertEquals(originalQuery.replace("logstash-*", "tenantName-logstash-*"), modifiedQuery);
	}
	
	@Test
	public void shouldReplaceIndiciesInMQuery() {
		TenantAliasCreator mockTenantAliasCreator = mock(TenantAliasCreator.class);
		when(mockTenantAliasCreator.fetchTenantAlias("logstash-*")).thenReturn("tenantName-logstash-*");
		
		ElasticsearchQueryModifier m = new ElasticsearchQueryModifier(mockTenantAliasCreator);
		String originalQuery = "{\"index\":\"logstash-*\",\"ignore_unavailable\":true}\n" + 
				"{\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041572}}}],\"must_not\":[]}}}},\"size\":500,\"sort\":{\"@timestamp\":\"desc\"},\"fields\":[\"*\",\"_source\"],\"script_fields\":{},\"fielddata_fields\":[\"@timestamp\",\"received_at\"]}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"3\":{\"terms\":{\"field\":\"cf_app_name\",\"size\":25,\"order\":{\"_count\":\"desc\"}},\"aggs\":{\"2\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"30s\",\"pre_zone\":\"+01:00\",\"pre_zone_adjust_large_interval\":true,\"min_doc_count\":1,\"extended_bounds\":{\"min\":1428682141570,\"max\":1428683041570}},\"aggs\":{\"4\":{\"terms\":{\"field\":\"verb\",\"size\":5,\"order\":{\"_count\":\"desc\"}}}}}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041572}}}],\"must_not\":[]}}}}}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"2\":{\"terms\":{\"field\":\"cf_app_name\",\"size\":25,\"order\":{\"_count\":\"desc\"}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041572}}}],\"must_not\":[]}}}}}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"2\":{\"terms\":{\"field\":\"status\",\"size\":10,\"order\":{\"_count\":\"desc\"}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041572}}}],\"must_not\":[]}}}}}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"2\":{\"terms\":{\"field\":\"http_user_agent\",\"size\":25,\"order\":{\"_count\":\"desc\"}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141572,\"lte\":1428683041573}}}],\"must_not\":[]}}}}}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"2\":{\"terms\":{\"field\":\"geoip.ip\",\"size\":25,\"order\":{\"_count\":\"desc\"}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141573,\"lte\":1428683041573}}}],\"must_not\":[]}}}}}\n" + 
				"{\"index\":\"logstash-*\",\"search_type\":\"count\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":0,\"aggs\":{\"3\":{\"terms\":{\"field\":\"cf_app_name\",\"size\":25,\"order\":{\"1.50\":\"desc\"}},\"aggs\":{\"1\":{\"percentiles\":{\"field\":\"response_time\",\"percents\":[50,95]}},\"2\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"30s\",\"pre_zone\":\"+01:00\",\"pre_zone_adjust_large_interval\":true,\"min_doc_count\":1,\"extended_bounds\":{\"min\":1428682141572,\"max\":1428683041572}},\"aggs\":{\"1\":{\"percentiles\":{\"field\":\"response_time\",\"percents\":[50,95]}}}}}}},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"query\":{\"filtered\":{\"query\":{\"query_string\":{\"query\":\"*\",\"analyze_wildcard\":true}},\"filter\":{\"bool\":{\"must\":[{\"query\":{\"match\":{\"@type\":{\"query\":\"cloudfoundry_doppler\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"event_type\":{\"query\":\"LogMessage\",\"type\":\"phrase\"}}}},{\"query\":{\"match\":{\"source_type\":{\"query\":\"RTR\",\"type\":\"phrase\"}}}},{\"query\":{\"query_string\":{\"analyze_wildcard\":true,\"query\":\"*\"}}},{\"range\":{\"@timestamp\":{\"gte\":1428682141573,\"lte\":1428683041573}}}],\"must_not\":[]}}}}}";
		String modifiedQuery = m.ReplaceIndicesWithTenantAliases(originalQuery);
		
		assertEquals(originalQuery.replace("logstash-*", "tenantName-logstash-*"), modifiedQuery);
	}
	
	@Test
	public void shouldReplaceMultipleDifferentIndiciesInMQuery() {
		TenantAliasCreator mockTenantAliasCreator = mock(TenantAliasCreator.class);
		when(mockTenantAliasCreator.fetchTenantAlias("logstash-2015.03.28")).thenReturn("tenantName-logstash-2015.03.28");
		when(mockTenantAliasCreator.fetchTenantAlias("logstash-2015.03.29")).thenReturn("tenantName-logstash-2015.03.29");
		
		ElasticsearchQueryModifier m = new ElasticsearchQueryModifier(mockTenantAliasCreator);
		String originalQuery = 
				"{\"index\":\"logstash-2015.03.28\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":500,\"sort\":{\"@timestamp\":\"desc\"},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"aggs\":{\"2\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"30s\",\"pre_zone\":\"+01:00\",\"pre_zone_adjust_large_interval\":true,\"min_doc_count\":0,\"extended_bounds\":{\"min\":1428678200944,\"max\":1428679100944}}}},\"query\":{\"filtered\":{\"query\":{\"match_all\":{}},\"filter\":{\"bool\":{\"must\":[{\"range\":{\"@timestamp\":{\"gte\":1428678200944,\"lte\":1428679100944}}}],\"must_not\":[]}}}},\"fields\":[\"*\",\"_source\"],\"script_fields\":{},\"fielddata_fields\":[\"@timestamp\",\"received_at\"]}" +
				"{\"index\":\"logstash-2015.03.29\",\"ignore_unavailable\":true}\n" + 
				"{\"size\":500,\"sort\":{\"@timestamp\":\"desc\"},\"highlight\":{\"pre_tags\":[\"@kibana-highlighted-field@\"],\"post_tags\":[\"@/kibana-highlighted-field@\"],\"fields\":{\"*\":{}}},\"aggs\":{\"2\":{\"date_histogram\":{\"field\":\"@timestamp\",\"interval\":\"30s\",\"pre_zone\":\"+01:00\",\"pre_zone_adjust_large_interval\":true,\"min_doc_count\":0,\"extended_bounds\":{\"min\":1428678200944,\"max\":1428679100944}}}},\"query\":{\"filtered\":{\"query\":{\"match_all\":{}},\"filter\":{\"bool\":{\"must\":[{\"range\":{\"@timestamp\":{\"gte\":1428678200944,\"lte\":1428679100944}}}],\"must_not\":[]}}}},\"fields\":[\"*\",\"_source\"],\"script_fields\":{},\"fielddata_fields\":[\"@timestamp\",\"received_at\"]}";

		String modifiedQuery = m.ReplaceIndicesWithTenantAliases(originalQuery);
		
		assertEquals(originalQuery
						.replace("logstash-2015.03.28", "tenantName-logstash-2015.03.28")
						.replace("logstash-2015.03.29", "tenantName-logstash-2015.03.29"), 
					 modifiedQuery);
	}
	
	@Test
	public void shouldNotReplaceKibanaIndicies() {
		TenantAliasCreator mockTenantAliasCreator = mock(TenantAliasCreator.class);
		when(mockTenantAliasCreator.fetchTenantAlias(".kibana")).thenReturn(".kibana");
		
		ElasticsearchQueryModifier m = new ElasticsearchQueryModifier(mockTenantAliasCreator);
		String originalQuery = "{\"docs\":[{\"_index\":\".kibana\",\"_type\":\"config\",\"_id\":\"4.0.1\"}]}";
		String modifiedQuery = m.ReplaceIndicesWithTenantAliases(originalQuery);
		
		assertEquals(originalQuery, modifiedQuery);
	}

}

/**
{"docs":[{"_index":".kibana","_type":"config","_id":"4.0.1"}]}

{"index":"logstash-*","ignore_unavailable":true}
{"size":500,"sort":{"@timestamp":"desc"},"highlight":{"pre_tags":["@kibana-highlighted-field@"],"post_tags":["@/kibana-highlighted-field@"],"fields":{"*":{}}},"aggs":{"2":{"date_histogram":{"field":"@timestamp","interval":"30s","pre_zone":"+01:00","pre_zone_adjust_large_interval":true,"min_doc_count":0,"extended_bounds":{"min":1428678200944,"max":1428679100944}}}},"query":{"filtered":{"query":{"match_all":{}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"gte":1428678200944,"lte":1428679100944}}}],"must_not":[]}}}},"fields":["*","_source"],"script_fields":{},"fielddata_fields":["@timestamp","received_at"]}
*/