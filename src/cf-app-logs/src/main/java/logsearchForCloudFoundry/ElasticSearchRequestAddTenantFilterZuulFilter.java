package logsearchForCloudFoundry;

import java.io.BufferedReader;
import java.io.IOException;
import java.lang.reflect.Field;
import java.nio.charset.Charset;

import javax.servlet.ServletInputStream;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;
import org.springframework.util.Assert;
import org.springframework.util.ReflectionUtils;

import com.netflix.zuul.ZuulFilter;
import com.netflix.zuul.context.RequestContext;
import com.netflix.zuul.http.HttpServletRequestWrapper;
import com.netflix.zuul.http.ServletInputStreamWrapper;

public class ElasticSearchRequestAddTenantFilterZuulFilter extends ZuulFilter {

	private Field requestField;
	private TenantAliasCreator tenantAliasCreator;
	static Logger log = Logger.getLogger(ElasticSearchRequestAddTenantFilterZuulFilter.class.getName());
	
	public ElasticSearchRequestAddTenantFilterZuulFilter(TenantAliasCreator tenantAliasCreator) {
		this.tenantAliasCreator = tenantAliasCreator;
		this.requestField = ReflectionUtils.findField(HttpServletRequestWrapper.class,
				"req", HttpServletRequest.class);
		Assert.notNull(this.requestField, "HttpServletRequestWrapper.req field not found");
		this.requestField.setAccessible(true);
	}

	@Override
	public String filterType() {
		return "pre";
	}

	@Override
	public int filterOrder() {
		return -1;
	}

	@Override
	public boolean shouldFilter() {
		RequestContext ctx = RequestContext.getCurrentContext();
		HttpServletRequest request = ctx.getRequest();
		
		if (request.getRequestURI().startsWith("/elasticsearch")) {
			log.debug("Filtering request:" + request.getRequestURI());
			return true;
		}
		
		return false;
	}

	@Override
	public Object run() {
		RequestContext ctx = RequestContext.getCurrentContext();
		HttpServletRequest request = ctx.getRequest();

		ElasticSearchRequestTenantFilterRequestWrapper wrapper = null;
		if (request instanceof HttpServletRequestWrapper) {
			HttpServletRequest wrapped = (HttpServletRequest) ReflectionUtils.getField(
					this.requestField, request);
			wrapper = new ElasticSearchRequestTenantFilterRequestWrapper(wrapped, tenantAliasCreator);
			ReflectionUtils.setField(this.requestField, request, wrapper);
		}
		else {
			wrapper = new ElasticSearchRequestTenantFilterRequestWrapper(request, tenantAliasCreator);
			ctx.setRequest(wrapper);
		}
		return null;
	}

	private class ElasticSearchRequestTenantFilterRequestWrapper extends HttpServletRequestWrapper {

		private HttpServletRequest request;

		private byte[] contentData;

		private int contentLength;

		private ElasticsearchQueryModifier esQueryModifier;

		public ElasticSearchRequestTenantFilterRequestWrapper(HttpServletRequest request, TenantAliasCreator tenantAliasCreator) {
			super(request);
			this.request = request;
			this.esQueryModifier = new ElasticsearchQueryModifier(tenantAliasCreator);
		}

		@Override
		public int getContentLength() {
			if (super.getContentLength() <= 0) {
				return super.getContentLength();
			}
			if (this.contentData == null) {
				buildContentData();
			}
			return this.contentLength;
		}

		@Override
		public ServletInputStream getInputStream() throws IOException {
			if (this.contentData == null) {
				buildContentData();
			}
			return new ServletInputStreamWrapper(this.contentData);
		}

		private synchronized void buildContentData() {
			try {
				StringBuffer jb = new StringBuffer();
				String line = null;
	
			    BufferedReader reader = request.getReader();
				while ((line = reader.readLine()) != null) {
				  jb.append(line + "\n");
				}
				String modifiedQuery = esQueryModifier.ReplaceIndicesWithTenantAliases(jb.toString());
				this.contentData = modifiedQuery.getBytes(Charset.forName("UTF-8"));
				this.contentLength = this.contentData.length;
			}
			catch (Exception e) {
				throw new IllegalStateException("Failed to rewrite ES query to use tenant specific aliases", e);
			}
		}

	}

}