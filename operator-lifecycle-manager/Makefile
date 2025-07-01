# VERSION defines the project version for the bundle.
# Update this value when you upgrade the version of your project.
# To re-generate a bundle for another specific version without changing the standard setup, you can:
# - use the VERSION as arg of the bundle target (e.g make bundle VERSION=0.0.2)
# - use environment variables to overwrite this value (e.g export VERSION=0.0.2)

# IMPORTANT: Respect the semantic versioning rules (https://semver.org) when updating the VERSION. We use major channel subscriptions so any minor or patch updates will be automatically
# upgraded by the OLM. Only major version updates will require manual intervention to upgrade.
VERSION ?= 2.7.0
K8S_SAFE_VERSION := $(shell echo $(VERSION) | tr . -)
CRD_VERSION ?= v1alpha1
MAJOR_OPERATOR_VERSION ?= v$(shell echo $(VERSION) | cut -d. -f1)

# CHANNELS define the bundle channels used in the bundle.
# Add a new line here if you would like to change its default config. (E.g CHANNELS = "candidate,fast,stable")
# To re-generate a bundle for other specific channels without changing the standard setup, you can:
# - use the CHANNELS as arg of the bundle target (e.g make bundle CHANNELS=candidate,fast,stable)
# - use environment variables to overwrite this value (e.g export CHANNELS="candidate,fast,stable")
ifneq ($(origin CHANNELS), undefined)
BUNDLE_CHANNELS := --channels=$(CHANNELS)
endif

# DEFAULT_CHANNEL defines the default channel used in the bundle.
# Add a new line here if you would like to change its default config. (E.g DEFAULT_CHANNEL = "stable")
# To re-generate a bundle for any other default channel without changing the default setup, you can:
# - use the DEFAULT_CHANNEL as arg of the bundle target (e.g make bundle DEFAULT_CHANNEL=stable)
# - use environment variables to overwrite this value (e.g export DEFAULT_CHANNEL="stable")
ifneq ($(origin DEFAULT_CHANNEL), undefined)
BUNDLE_DEFAULT_CHANNEL := --default-channel=$(DEFAULT_CHANNEL)
endif
BUNDLE_METADATA_OPTS ?= $(BUNDLE_CHANNELS) $(BUNDLE_DEFAULT_CHANNEL)

# IMAGE_TAG_BASE defines the docker.io namespace and part of the image name for remote images.
# This variable is used to construct full image tags for bundle and catalog images.
#
# For example, running 'make bundle-build-push catalog-build-push' will build and push both
# docker.io/tytn/operator-bundle:$VERSION and docker.io/tytn/operator-bundle-catalog:$VERSION.
IMAGE_TAG_BASE ?= tytn/operator
CONTROLLER_IMAGE ?= $(IMAGE_TAG_BASE):$(VERSION)
BUNDLE_IMAGE ?= $(IMAGE_TAG_BASE)-bundle:$(VERSION)
CATALOG_IMAGE ?= $(IMAGE_TAG_BASE)-catalog:$(VERSION)
IMAGE_PLATFORMS ?= linux/amd64

# BUNDLE_GEN_FLAGS are the flags passed to the operator-sdk generate bundle command
BUNDLE_GEN_FLAGS ?= -q --overwrite --version $(VERSION) $(BUNDLE_METADATA_OPTS)

# USE_IMAGE_DIGESTS defines if images are resolved via tags or digests
# You can enable this value if you would like to use SHA Based Digests
# To enable set flag to true
USE_IMAGE_DIGESTS ?= false
ifeq ($(USE_IMAGE_DIGESTS), true)
	BUNDLE_GEN_FLAGS += --use-image-digests
endif

# Set the Operator SDK version to use. By default, what is installed on the system is used.
# This is useful for CI or a project to utilize a specific version of the operator-sdk toolkit.
OPERATOR_SDK_VERSION ?= v1.39.1

# Source and destination paths for chart syncing
SOURCE_CHART_PATH ?= ../charts/inference-stack
DEST_CHART_PATH ?= helm-charts/inference-stack

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Dependencies

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')

.PHONY: kustomize
KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
ifeq (,$(wildcard $(KUSTOMIZE)))
ifeq (,$(shell which kustomize 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(KUSTOMIZE)) ;\
	curl -sSLo - https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v5.4.3/kustomize_v5.4.3_$(OS)_$(ARCH).tar.gz | \
	tar xzf - -C bin/ ;\
	}
else
KUSTOMIZE = $(shell which kustomize)
endif
endif

.PHONY: helm-operator
HELM_OPERATOR = $(shell pwd)/bin/helm-operator
helm-operator: ## Download helm-operator locally if necessary, preferring the $(pwd)/bin path over global if both exist.
ifeq (,$(wildcard $(HELM_OPERATOR)))
ifeq (,$(shell which helm-operator 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(HELM_OPERATOR)) ;\
	curl -sSLo $(HELM_OPERATOR) https://github.com/operator-framework/operator-sdk/releases/download/v1.39.1/helm-operator_$(OS)_$(ARCH) ;\
	chmod +x $(HELM_OPERATOR) ;\
	}
else
HELM_OPERATOR = $(shell which helm-operator)
endif
endif

.PHONY: operator-sdk
OPERATOR_SDK ?= bin/operator-sdk
operator-sdk: ## Download operator-sdk locally if necessary.
ifeq (,$(wildcard $(OPERATOR_SDK)))
ifeq (, $(shell which operator-sdk 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPERATOR_SDK)) ;\
	curl -sSLo $(OPERATOR_SDK) https://github.com/operator-framework/operator-sdk/releases/download/$(OPERATOR_SDK_VERSION)/operator-sdk_$(OS)_$(ARCH) ;\
	chmod +x $(OPERATOR_SDK) ;\
	}
else
OPERATOR_SDK = $(shell which operator-sdk)
endif
endif

.PHONY: opm
OPM = bin/opm
opm: ## Download opm locally if necessary.
ifeq (,$(wildcard $(OPM)))
ifeq (,$(shell which opm 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(OPM)) ;\
	curl -sSLo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/v1.51.0/$(OS)-$(ARCH)-opm ;\
	chmod +x $(OPM) ;\
	}
else
OPM = $(shell which opm)
endif
endif

.PHONY: yq
YQ = bin/yq
yq: ## Download yq locally if necessary.
ifeq (,$(wildcard $(YQ)))
ifeq (,$(shell which yq 2>/dev/null))
	@{ \
	set -e ;\
	mkdir -p $(dir $(YQ)) ;\
	curl -sSLo $(YQ) https://github.com/mikefarah/yq/releases/latest/download/yq_$(OS)_$(ARCH) ;\
	chmod +x $(YQ) ;\
	}
else
YQ = $(shell which yq)
endif
endif

.PHONY: sed
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  # On macOS, require gsed
  ifeq (,$(shell which gsed 2>/dev/null))
    $(error "gsed is required on macOS but not found. Please install it via 'brew install gnu-sed'")
  endif
  SED = gsed
else
  # On other systems, just use sed
  SED = sed
endif

.PHONY: install
install: kustomize helm-operator operator-sdk opm yq ## Install dependencies

##@ Chart Sync

.PHONY: verify-chart
verify-chart: ## Verify source chart exists
	@if [ ! -d "$(SOURCE_CHART_PATH)" ]; then \
		echo "Error: Source chart directory $(SOURCE_CHART_PATH) does not exist"; \
		exit 1; \
	fi

.PHONY: sync-charts
sync-charts: verify-chart ## Sync charts from parent directory
	@echo "Syncing charts from $(SOURCE_CHART_PATH) to $(DEST_CHART_PATH)"
	mkdir -p $(DEST_CHART_PATH)
	rm -rf $(DEST_CHART_PATH)
	cp -r $(SOURCE_CHART_PATH) $(DEST_CHART_PATH)
	@echo "Chart sync complete"

##@ Deployment

.PHONY: bundle
bundle: sed yq kustomize operator-sdk sync-charts ## Generate bundle manifests and metadata, then validate generated files.
	rm -rf bundle
	$(OPERATOR_SDK) generate kustomize manifests -q
	$(SED) -i 's/version:.*/version: $(CRD_VERSION)/g' watches.yaml
	$(SED) -i 's/operatorVersion:.*/operatorVersion: $(MAJOR_OPERATOR_VERSION)/g' watches.yaml
	$(YQ) -n '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--leader-election-id=inference-stack-operator-$(K8S_SAFE_VERSION)"}]' > config/manager/deploymentPatch.yaml
	cd config/manager && $(KUSTOMIZE) edit set image controller=$(CONTROLLER_IMAGE)
	$(YQ) -n '[{"op": "replace", "path": "/spec/customresourcedefinitions/owned/0/version", "value": "$(CRD_VERSION)"}]' > config/manifests/clusterServiceVersionPatch.yaml
	cd config/manifests && $(KUSTOMIZE) edit set namesuffix -- -$(K8S_SAFE_VERSION)
	$(KUSTOMIZE) build config/manifests | $(OPERATOR_SDK) generate bundle $(BUNDLE_GEN_FLAGS)
	$(OPERATOR_SDK) bundle validate ./bundle

DOCKER ?= docker 

.PHONY: bundle-build
bundle-build: bundle ## Build then pushes the bundle and operator images.
	$(DOCKER) build -t $(CONTROLLER_IMAGE) . --platform $(IMAGE_PLATFORMS)
	$(DOCKER) build -f bundle.Dockerfile -t $(BUNDLE_IMAGE) . --platform $(IMAGE_PLATFORMS)

.PHONY: bundle-push
bundle-push: bundle-build
	$(DOCKER) push $(CONTROLLER_IMAGE) --platform $(IMAGE_PLATFORMS)
	$(DOCKER) push $(BUNDLE_IMAGE) --platform  $(IMAGE_PLATFORMS)

.PHONY: bundle-build-push
bundle-build-push: bundle-push

# Build and push the catalog image, you need to have updated the catalog/operator_catalog.yaml file with the new version to add it 
# to the catalog. The catalog image is used to deploy the catalog to the cluster.

.PHONY: catalog
catalog: opm ## Build and push the catalog image.
	mkdir -p catalog/configs
	$(OPM) alpha render-template semver -o yaml < catalog/operator_catalog.yaml > catalog/configs/catalog.yaml
	$(OPM) validate catalog/configs

.PHONY: catalog-build
catalog-build: catalog
	$(DOCKER) build -f catalog.Dockerfile --build-arg "CATALOG_DIR=catalog/configs" -t $(CATALOG_IMAGE) . --platform $(IMAGE_PLATFORMS)

.PHONY: catalog-push
catalog-push: catalog-build
	$(DOCKER) push $(CATALOG_IMAGE) --platform $(IMAGE_PLATFORMS)

.PHONY: catalog-build-push
catalog-build-push: catalog-push


