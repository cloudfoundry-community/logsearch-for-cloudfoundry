import $ from "jquery";
import _ from "lodash";

import notify from 'ui/notify';
import uiModules from 'ui/modules';

import "plugins/authentication/user.less";
import chrome from "ui/chrome";
import indexView from "plugins/authentication/user.html";

chrome
  .setRootTemplate(indexView)
  .setRootController('ui', function ($http, $scope) {
  var ui = this;
  ui.loading = false;

  ui.refresh = function () {
    ui.loading = true;

    ui.user_name = "-" // user name to show in html template

    // go ahead and get the info you want
    return $http
    .get(chrome.addBasePath('/account'))
    .then(function (resp) {

      if (ui.fetchError) {
        ui.fetchError.clear();
        ui.fetchError = null;
      }

      // fill in data
      ui.user_name = resp.data.raw.user_name;

    })
    .catch(function () {
      if (ui.fetchError) return;
      ui.fetchError = notify.error('Failed to request user details. Perhaps your server is down?');
    })
    .then(function () {
      ui.loading = false;
    });
  };

  ui.refresh();
});
