package logsearchForCloudFoundry;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.cloud.security.oauth2.sso.EnableOAuth2Sso;
import org.springframework.cloud.security.oauth2.sso.OAuth2SsoConfigurerAdapter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@Configuration
@ComponentScan
@EnableAutoConfiguration
@RestController
@RequestMapping("/")
@EnableOAuth2Sso
@EnableZuulProxy
public class LogsearchForCloudFoundry {

	@Autowired
	private TenantAliasCreator tenantAliasCreator;
	
	@Bean
	public ElasticSearchRequestAddTenantFilterZuulFilter myFilter() {
	    return new ElasticSearchRequestAddTenantFilterZuulFilter(tenantAliasCreator);
	}
	
	public static void main(String[] args) {
		SpringApplication.run(LogsearchForCloudFoundry.class, args);
	}
	
	 @Component
	 public static class LoginConfigurer extends OAuth2SsoConfigurerAdapter {

	 	@Override
	 	public void configure(HttpSecurity http) throws Exception {
	 		// Disable CSRF protection (leave that up to the backend we're proxying to, eg Kibana and/or Elasticsearch)
	        http.csrf().disable();
	        
	 		http.antMatcher("/**")
	 			.authorizeRequests()
	 			.anyRequest()
	 			.authenticated();
	 	}

	 }
}
 