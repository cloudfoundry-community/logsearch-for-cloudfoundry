# How to use

1. Fill **secret.yml** according to your environment
2. Run:

	```
	fly -t example set-pipeline --pipeline example --config pipeline.yml --load-vars-from secret.yml
	fly -t example unpause-pipeline --pipeline example
	```

For more information about Concourse please refer to [concourse.ci](https://concourse.ci/using-concourse.html)
