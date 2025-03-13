FROM scratch

LABEL operators.operatorframework.io.bundle.mediatype.v1=plain
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=model-orchestra-operator-0.1.0
LABEL operators.operatorframework.io.bundle.channels.v1=stable
LABEL operators.operatorframework.io.bundle.channel.default.v1=stable

COPY bundle-0.1.0/manifests /manifests/
COPY bundle-0.1.0/metadata /metadata/
