package logsearchForCloudFoundry;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.security.oauth2.client.OAuth2RestOperations;
import org.springframework.stereotype.Component;

@Component
@Scope(value="session", proxyMode=ScopedProxyMode.TARGET_CLASS)
public class SimpleUAAClient {
	
	@Autowired
	private OAuth2RestOperations restTemplate;
	private UserInfo userInfo = null;	
	
	@Value("${cloudfoundry.uaaUri}")
    private String uaaUri;
	
	public UserInfo getUserInfo() {
		if (userInfo == null) {
			userInfo  = restTemplate.getForObject(uaaUri+"/userinfo", UserInfo.class);
		}
		return userInfo ;
	}


}