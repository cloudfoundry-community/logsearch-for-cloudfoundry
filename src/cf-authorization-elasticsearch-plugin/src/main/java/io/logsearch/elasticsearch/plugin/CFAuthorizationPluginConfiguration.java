package io.logsearch.elasticsearch.plugin;

import org.elasticsearch.ElasticsearchParseException;
import org.elasticsearch.common.inject.Inject;
import org.elasticsearch.common.xcontent.XContentParser;
import org.elasticsearch.common.xcontent.yaml.YamlXContent;
import org.elasticsearch.env.Environment;

import java.io.IOException;
import java.nio.file.Path;

import static java.nio.charset.StandardCharsets.UTF_8;
import static java.nio.file.Files.newBufferedReader;
import static org.elasticsearch.common.io.Streams.copyToString;

/**
 * Example configuration.
 */
public class CFAuthorizationPluginConfiguration {
    private String CFApiUri = "not set in config";

    @Inject
    public CFAuthorizationPluginConfiguration(Environment env) throws IOException {
        // The directory part of the location matches the artifactId of this plugin
        Path configFile = env.configFile().resolve("cf-authorization.yml");
        String contents = copyToString(newBufferedReader(configFile, UTF_8));
        XContentParser parser = YamlXContent.yamlXContent.createParser(contents);

        String currentFieldName = null;
        XContentParser.Token token = parser.nextToken();
        assert token == XContentParser.Token.START_OBJECT;
        while ((token = parser.nextToken()) != XContentParser.Token.END_OBJECT) {
            if (token == XContentParser.Token.FIELD_NAME) {
                currentFieldName = parser.currentName();
            } else if (token.isValue()) {
                if ("CF_API_URI".equals(currentFieldName)) {
                    CFApiUri = parser.text();
                } else {
                    throw new ElasticsearchParseException("Unrecognized config key: {}", currentFieldName);
                }
            } else {
                throw new ElasticsearchParseException("Unrecognized config key: {}", currentFieldName);
            }
        }
    }

    public String getCFApiUri() {
        return CFApiUri;
    }
}
