[<- home page](../README.md)
### For developers

If for any reason you need to extend or modify Logsearch-for-cloudfoundry functionallity please read this page carefully.

Before anything else, it makes sense to check [Customization](customization.md) page for ways of extending Logsearch-for-cloudfoundry **by using configuration options** (without changing source code).

If you still feel like to change source code then **please mind the following points**:

* When changing fields parsing consider [default mappings](features.md#elasticsearch-mappings). Make sure that default mappings are still applied after the changes in parsing.

* Make sure that your custom parsing rules have no conflicts with [default parsing rules](logs-parsing.md#parsing-rules). If necessary update related stuff such as Elasticsearch mappings, [Kibana objects](features.md#kibana-saved-objects) etc.

* If you use Kibana _authentication_ feature then make sure it works after you changed parsing (this feature relies on some fields, read about the [feature](features.md#kibana-authentication-plugin) for more details).

* When developing parsing rules run [tests](#tests) for regression. Add new tests to check your custom logic.

Additionally, you can check out [Troubleshooting](troubleshooting.md) page for tips on Logsearch deployment troubleshooting. It can be useful for you when testing your custom changes.

For questions / issues / contribution please follow [Contribution](#contribution) section below.

#### Creating a dev release

Logsearch-for-cloudfoundry uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) and [BOSH package vendoring](https://bosh.io/docs/package-vendoring.html). If you have problems creating a release, check that you've updated the submodules and have a BOSH CLI version that supports vendoring (i.e., `bosh --version` is at least v2.0.36).

```bash
$ git clone --recursive https://github.com/cloudfoundry-community/logsearch-for-cloudfoundry
$ cd logsearch-for-cloudfoundry
$ bosh create-release
$ bosh -e your-director-name upload-release
```

#### Tests

##### Logsearch-config tests

Tests and build scripts are placed in [logsearch-config](../src/logsearch-config) directory. See `Rakefile` file for build tasks and `bin/*` for build scripts.

The project includes the following tests:

* [Unit tests](../src/logsearch-config/test/logstash-filters/snippets) for parsing snippets (test each parsing snippet)
* [Integration tests](./src/logsearch-config/test/logstash-filters/it) for snippets (test whole parsing config built from all snippets - as they used in prod)
* JSON validation check
* YAML validation check

Before running tests **install dependencies**:
```
cd src/logsearch-config
bin/install-dependencies
```
You don't need to execute it each time you run tests.

Then **run tests** with one of possible options:

all tests
```
bin/test
```
unit tests (all or specific)
```
bin/test utest
```
```
bin/test utest test/logstash-filters/snippets/platform-spec.rb
```
integartion tests (all or specific)
```
bin/test itest
```
```
bin/test itest test/logstash-filters/it/app-it-spec.rb
```
validation checks (json or yaml)
```
bin/test json
```
```
bin/test yaml
```
##### Smoke tests

There are also smoke tests running as a BOSH [job](../jobs/smoke-tests/spec). Smoke tests are hosted in a separate [repo](https://github.com/cloudfoundry-community/logsearch-smoke-tests/).

#### Contribution

If you detect any issue please submit it here in GitHub so that we can be aware of it and fix it.
If you are ready to contribute you are welcome with pull requests.

If you have any questions - please contact us on GitHub.

</br>[<- prev page](links.md)
