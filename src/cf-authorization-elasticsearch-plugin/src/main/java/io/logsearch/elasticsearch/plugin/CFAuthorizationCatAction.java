package io.logsearch.elasticsearch.plugin;

import org.elasticsearch.client.Client;
import org.elasticsearch.common.Table;
import org.elasticsearch.common.inject.Inject;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.rest.*;
import org.elasticsearch.rest.action.cat.AbstractCatAction;
import org.elasticsearch.rest.action.support.RestTable;

import static org.elasticsearch.rest.RestRequest.Method.GET;

public class CFAuthorizationCatAction extends AbstractCatAction {
    private final CFAuthorizationPluginConfiguration config;

    @Inject
    public CFAuthorizationCatAction(Settings settings, RestController controller,
            Client client, CFAuthorizationPluginConfiguration config) {
        super(settings, controller, client);
        this.config = config;
        controller.registerHandler(GET, "/_cat/cf-authorization", this);
    }

    @Override
    protected void doRequest(final RestRequest request, final RestChannel channel, final Client client) {
        Table table = getTableWithHeader(request);
        table.startRow();
        table.addCell(config.getCFApiUri());
        table.endRow();
        try {
            channel.sendResponse(RestTable.buildResponse(table, channel));
        } catch (Throwable e) {
            try {
                channel.sendResponse(new BytesRestResponse(channel, e));
            } catch (Throwable e1) {
                logger.error("failed to send failure response", e1);
            }
        }
    }

    @Override
    protected void documentation(StringBuilder sb) {
        sb.append(documentation());
    }

    public static String documentation() {
        return "/_cat/cf-authorization\n";
    }

    @Override
    protected Table getTableWithHeader(RestRequest request) {
        final Table table = new Table();
        table.startHeaders();
        table.addCell("CF_API_URI", "desc:CF_API_URI");
        table.endHeaders();
        return table;
    }
}
