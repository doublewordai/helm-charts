
# Working with the Takeoff helm chart
## Installing Takeoff  

  
1. Prepare any value overrides. Aside from the standard [values.yaml](https://raw.githubusercontent.com/titanml/helm-charts/main/charts/takeoff/values.yaml), you may want to launch takeoff with some of the deployment context specific overrides typically used for running takeoff on [gke](https://raw.githubusercontent.com/titanml/helm-charts/main/charts/takeoff/overwrites/values-gke.yaml) and [eks](https://raw.githubusercontent.com/titanml/helm-charts/main/charts/takeoff/overwrites/values-eks.yaml). You'll also need to provide an access token for using private huggingface hub models, either by a secret_values file or just by using `--set secrets.TAKEOFF_ACCESS_TOKEN=hf_xxxxx`.

2. Prepare the namespace you want to use. As an example here we'll use takeoff-test-1.  
a. If you don't already have a namespace to use, you'll want to do something like `kubectl create namespace takeoff-test-1`  
  
  
3. Ensure you've got access to the takeoff docker repo.
a. Log in to docker hub, or locate the relevant docker config file if you're importing it from elsewhere.  
b. `kubectl create secret docker-registry takeoff-regcred --from-file=<docker_config_file_location> -n takeoff-test-1`- if you've logged in to docker your config file is most likely at `~/.docker/config.json`.  
  
4. Setup the takeoff repo:  
a. `helm repo add titanml https://titanml.github.io/helm-charts`  
b. `helm repo update`  
c. use `helm search repo titanml` and check you can see the takeoff chart  
  
5. Install takeoff  
a. e.g. on eks, providing access to private huggingface hub models: `helm install takeoff titanml/takeoff -f values-eks.yaml -n takeoff-test-1 --set secrets.TAKEOFF_ACCESS_TOKEN=hf_xxxxx`  
Note that the first argument is the release name - we're using `takeoff` throughout these instructions - and the second specifies the repo/chart name to install.  
  
6. Setup some applications.  
a. Configure `applications_values.yaml` (or whatever yaml you want to use) with the applications you want to use. There's an example [here](https://raw.githubusercontent.com/titanml/helm-charts/main/charts/takeoff/application_values.yaml). Pay attention to cacheStorageClass - you'll need to set this appropriately for whichever deployment context you're using.  
b. Add these applications to the cluster with `helm upgrade takeoff titanml/takeoff -f application_values.yaml --reuse-values -n takeoff-test-1`

  
## Updating Takeoff  
If you want to change some values, you'll want to use one of:
 - If you want to switch to a new set of values files: `helm upgrade
   takeoff titanml/takeoff -f values-local.yaml -f secret_values.yaml -n takeoff-test-1`  
- If you just want to override a setting (e.g. say you've decided you want to turn metrics on), you could use `helm upgrade takeoff titanml/takeoff --reuse-values -n takeoff-test-1 --set key=value`   
- If you want to override lots of settings via making a new values file and adding that in, you can do `helm upgrade takeoff titanml/takeoff -f new_values.yaml --reuse-values -n takeoff-test-1`   
 - If you want to upgrade the chart to a new version:
	 -  run `helm search repo titanml` to see what the latest version is
	 -  use `helm upgrade takeoff titanml/takeoff --version <version-name> --reuse-values -n takeoff-test-1`
