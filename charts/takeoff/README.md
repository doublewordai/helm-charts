# Takeoff

Takeoff is an inference stack for deploying LLMs and other deep learning models.

## TL;DR
```bash
helm repo add titanml titanml.github.io/helm-charts
helm install takeoff-console titanml/takeoff
```

## Configuration & installation details
### Architecture overview
The takeoff stack has two components: a "controller" - that provides an integrated openAI-compatible gateway & integrated monitoring system - and several "applications" that receive and respond to requests from the controller. 
Each application is a single, replicated model service.

#### Controller
To configure the controller service, provide:

```yaml
controller:
  config:
    # allowRemoteImages: false, // Whether to allow the user to specify url image requests
    # readerMessageTimeoutMs: 500, // How long between tokens before we timeout a reader.
    # reservedConsumers: "".to_string(), // Which consumers groups should buffer requests, rather than rejecting them
    # maxPromptStringBytes: 150000, // The maximum size of a prompt, in bytes
    # maxUserBatchSize: 1000, // The maximum allowed user batch size
    # bodySizeLimitBytes: 1024 * 1024 * 2, // The maximum body size
    # heartbeatCheckInterval: 1, // How frequently to check for dead readers. 0 means never
```

See the `server_config` section of the config file [here](https://docs.titanml.co/apis/launch_parameters) for available parameters (note the snake_case settings for the container itself, vs. camelCase here)
#### Applications

In order to make models available through the controller gateway, add a stanza to the `application` settings, under an application name. For example:

```yaml
applications:
  dummy-model: # must be url-safe! i.e. no underscores, or capitals.
    readerConfig:
      modelName: "TitanML/dummy_model"
      device: "cuda"
      consumerGroup: "primary"
    resources:
      limits:
        cpu: 100m
        memory: 128Mi
        nvidia.com/gpu: 1
      requests:
        cpu: 100m
        memory: 128Mi
        nvidia.com/gpu: 1
```

The `consumerGroup` setting is the `model` [key](https://platform.openai.com/docs/guides/text-generation) which you should provide to the controller's openAI compatible API service. 
To create a service backed by several different applications, set the same `consumerGroup` on each of them. 

See the `reader_config` section of the config file [here](https://docs.titanml.co/apis/launch_parameters) for available parameters for the `readerConfig` (note the snake_case settings for the container itself, vs. camelCase here)

#### Application Template

The base settings for all applications are provided in the `applicationTemplate` stanza. Changes to this section will apply to all deployed models. For example, to set an environment variable for all deployed applications:

```yaml
applicationTemplate:
  env:
    - name: MY_IMPORTANT_ENV_VAR
      value: "MY_IMPORTANT_ENV_VAR_VALUE"
```

### Prometheus metrics
This chart can be integrated with Prometheus. 
To enable, add `--set controller.exportPrometheusMetrics=true --set applicationTemplate.exportPrometheusMetrics=true`.

#### Integration with Prometheus Operator
It is necessary to have a working installation of the [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) for the integration to work. See the [takeoff-system](https://github.com/titanml/helm-charts/tree/main/charts/takeoff-system) chart for a single chart that provides all of the dependencies for takeoff to run at full functionality.

The chart will try to deploy ServiceMonitor objects for integration with Prometheus Operator installations. 
Ensure that the Prometheus Operator CustomResourceDefinitions are installed in the cluster or it will fail with the following error:

```
no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
```

### Autoscaling

Autoscaling for all applications can be enabled by adding 

```
--set applicationTemplate.scaling.enabled=true
```

For an individual application, 

```
--set <APPLICATION_NAME>.scaling.enabled=true
```

Where `<APPLICATION_NAME>` should be replaced with the application name defined in the top level `applications` key.

### Integration with Keda Operator
It is necessary to have a working installation of the [Keda](https://keda.sh/docs/2.16/concepts/) chart for the integration to work. See the [takeoff-system](https://github.com/titanml/helm-charts/tree/main/charts/takeoff-system) chart for a single chart that provides all of the dependencies for takeoff to run at full functionality.

The chart will try to deploy `ScaledObject` objects for integration with Keda installations. 
