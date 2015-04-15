package logsearchForCloudFoundry;

import io.searchbox.client.JestClient;
import io.searchbox.client.JestClientFactory;
import io.searchbox.client.JestResult;
import io.searchbox.client.config.HttpClientConfig;
import io.searchbox.cluster.State;
import io.searchbox.indices.aliases.AddAliasMapping;
import io.searchbox.indices.aliases.AliasMapping;
import io.searchbox.indices.aliases.ModifyAliases;
import io.searchbox.indices.aliases.RemoveAliasMapping;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.UUID;

import org.apache.log4j.Logger;
import org.cloudfoundry.client.lib.CloudCredentials;
import org.cloudfoundry.client.lib.CloudFoundryClient;
import org.cloudfoundry.client.lib.domain.CloudSpace;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.security.oauth2.client.OAuth2ClientContext;
import org.springframework.stereotype.Component;

import com.google.common.collect.ImmutableMap;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

@Component
@Scope(value="session", proxyMode=ScopedProxyMode.TARGET_CLASS)
public class TenantAliasCreator {
	@Autowired
	private OAuth2ClientContext oauth2Context;
	
	@Autowired
	private SimpleUAAClient uaaClient = null;
	
	@Value("${cloudfoundry.cloudControllerUri}")
    private String cloudControllerUri;
	
	@Value("${logsearch.elasticsearchAdminUri}")
    private String elasticsearchAdminUri;
	
	static Logger log = Logger.getLogger(TenantAliasCreator.class.getName());
	private CloudFoundryClient cloudFoundryClient = null;
	private JestClient jestClient = null;
	private Map<UUID, String> authorizedSpaces = new HashMap<UUID, String> ();
	private Map<String, String> tenantIndexAliases = new HashMap<String, String> ();

	private String tenantUsername;
	
	private URL getCloudControllerUrl() {
		URL cloudControllerUrl = null;
		try {
			cloudControllerUrl = new URL(cloudControllerUri);
		} catch (MalformedURLException e) {
			log.error(e);
			e.printStackTrace();
		}
		return cloudControllerUrl;
	}

	public String fetchTenantAlias(String originalIndexName) {
		setupTenantAliases();
		if (tenantIndexAliases.containsKey(originalIndexName)) {
			return tenantIndexAliases.get(originalIndexName);
		}
		return tenantUsername + "-" + originalIndexName;
	}
	
	private void setupTenantAliases() {	
		if (!tenantIndexAliases.isEmpty())
			return; //Only setup Tenant Aliases once / session
		
		tenantUsername = uaaClient.getUserInfo().getUserName();
		
		log.debug("Setting up tenant aliases for: " + tenantUsername);
		
		tenantIndexAliases.put(".kibana", ".kibana"); //Shared kibana index
		
		Map<String, Object> authorisedSpaceFilter = createAuthorisedSpacesFilter();
		ArrayList<String> indexNames = getIndexNames();
		
		ArrayList<AliasMapping> removeAliasActions = new ArrayList<AliasMapping>();
		ArrayList<AliasMapping> addAliasActions = new ArrayList<AliasMapping>();
		for (String indexName : indexNames) {
			if (indexName.contains("logstash-")) {
				String aliasName = tenantUsername + "-" + indexName;
				
				log.debug("Adding alias: " + aliasName + " for index: " + indexName);
				
				removeAliasActions.add(new RemoveAliasMapping.Builder(indexName, aliasName).build());
				addAliasActions.add(new AddAliasMapping.Builder(indexName, aliasName).setFilter(authorisedSpaceFilter).build());
				tenantIndexAliases.put(indexName, aliasName);
			}
		}
		ModifyAliases modifyAliases = new ModifyAliases.Builder(removeAliasActions).addAlias(addAliasActions).build();

		try {
			log.debug("Sending alias commands to ES: " + modifyAliases.toString());
			JestResult result = getJestClient().execute(modifyAliases);
	        if (!result.isSucceeded()) {
	        	throw new Exception(result.getErrorMessage());
	        }
		} catch (Exception e) {
			// TODO Auto-generated catch block
			log.error(e);
			e.printStackTrace();
		}
        
	}

	private ArrayList<String> getIndexNames() {
		ArrayList<String> indexNames = new ArrayList<String>();
		try {
			JestResult result = getJestClient().execute(new State.Builder().build());
			JsonObject indiciesJson = result.getJsonObject().getAsJsonObject("metadata").getAsJsonObject("indices");
			for (Entry<String, JsonElement> index : indiciesJson.entrySet()) {
				indexNames.add(index.getKey());
			}
		} catch (Exception e1) {
			log.error(e1);
			e1.printStackTrace();
		}
		return indexNames;
	}

	private Map<String, Object> createAuthorisedSpacesFilter() {
		fetchAuthorisedSpaces();
		Map<String, Object> authorizedSpaceFilter = ImmutableMap.<String, Object>builder()
	            .put("terms", ImmutableMap.<String, Set<UUID>>builder()
	                    .put("cf_space_id", authorizedSpaces.keySet())
	                    .build())
	            .build();
		return authorizedSpaceFilter;
	}
	
	private void fetchAuthorisedSpaces() {
		if (!authorizedSpaces.isEmpty())
			return; //Only lookup spaces once / session
		
		for (CloudSpace space : getCloudFoundryClient().getSpaces()) {
				authorizedSpaces.put(space.getMeta().getGuid(), space.getName());
		}
	}
	
	private JestClient getJestClient() {
		 if (this.jestClient == null) {
			 JestClientFactory factory = new JestClientFactory();
			 factory.setHttpClientConfig(new HttpClientConfig
			                        .Builder(elasticsearchAdminUri)
			                        .multiThreaded(true)
			                        .build());
			 this.jestClient = factory.getObject();
		 }
		 return this.jestClient;
	}

	private CloudFoundryClient getCloudFoundryClient() {
		if (this.cloudFoundryClient == null) {
			CloudCredentials credentials = new CloudCredentials(oauth2Context.getAccessToken());
			this.cloudFoundryClient = new CloudFoundryClient(credentials, getCloudControllerUrl());
		}
		return this.cloudFoundryClient;
	}
	
}

