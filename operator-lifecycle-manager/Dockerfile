# This build is to create a new version of the helm-operator that respects selector labels and skips reconciliation if the selector
# do not match. This is a temporary solution to use a fork until this issue is resolved in the main helm-operator repository: https://github.com/operator-framework/helm-operator-plugins/pull/431.
# The raiser of the issue made a fork with this fixed: https://github.com/stackrox/helm-operator.
FROM ubuntu as builder

RUN apt-get update && apt-get install -y git build-essential wget

RUN wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

RUN git clone https://github.com/stackrox/helm-operator.git helm-operator && \
    cd helm-operator && \
    make build && \
    make release && \
    cp dist/helm-operator_linux_amd64_v1/helm-operator /helm-operator-2

# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.39.1

COPY --from=builder /helm-operator-2 /usr/local/bin/helm-operator-2
ENTRYPOINT ["/usr/local/bin/helm-operator-2", "run", "--watches-file=./watches.yaml"]

ENV HOME=/opt/helm
COPY --chmod=777 watches.yaml ${HOME}/watches.yaml
COPY --chmod=777 helm-charts  ${HOME}/helm-charts

WORKDIR ${HOME}
