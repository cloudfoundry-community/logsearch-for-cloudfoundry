package io.logsearch.elasticsearch.plugin;

import org.elasticsearch.action.ActionModule;
import org.elasticsearch.common.component.LifecycleComponent;
import org.elasticsearch.common.inject.AbstractModule;
import org.elasticsearch.common.inject.Module;
import org.elasticsearch.common.inject.multibindings.Multibinder;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.plugins.Plugin;
import org.elasticsearch.repositories.RepositoriesModule;
import org.elasticsearch.rest.action.cat.AbstractCatAction;

import java.io.Closeable;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;

public class CFAuthorizationPlugin extends Plugin {

    private final Settings settings;

    public CFAuthorizationPlugin(Settings settings) {
        this.settings = settings;
    }

    @Override
    public String name() {
        return "cf-authorization plugin";
    }

    @Override
    public String description() {
        return "An Elasticsearch plugin that restricts access to log documents based on CF UAA credentials";
    }

    public void onModule(ActionModule actionModule) {
         actionModule.registerFilter(CFAuhorizationActionFilter.class);
     }

    public void onModule(RepositoriesModule repositoriesModule) {
    }

}
