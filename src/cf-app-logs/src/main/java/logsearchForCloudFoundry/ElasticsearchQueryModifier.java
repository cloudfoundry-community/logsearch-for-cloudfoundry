package logsearchForCloudFoundry;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ElasticsearchQueryModifier {

	private TenantAliasCreator tenantAliasCreator;

	public ElasticsearchQueryModifier(TenantAliasCreator tenantAliasCreator) {
		this.tenantAliasCreator = tenantAliasCreator;
	}

	public String ReplaceIndicesWithTenantAliases(String originalQuery) {
		Pattern pattern = Pattern.compile("\"index\":\"(logstash-.*?)\"");
        Matcher matcher = pattern.matcher(originalQuery);

        StringBuffer modifiedQuery = new StringBuffer(originalQuery.length());

        while(matcher.find())
        {
        	String indexName = matcher.group(1);
        	matcher.appendReplacement(modifiedQuery, "\"index\":\"" + Matcher.quoteReplacement(tenantAliasCreator.fetchTenantAlias(indexName)) + "\"");
        }
        
        matcher.appendTail(modifiedQuery);
		return modifiedQuery.toString();
	}

}
