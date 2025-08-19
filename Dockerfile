FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.5.28 /uv /uvx /usr/local/bin/

# Install system build tools
RUN --mount=type=cache,target=/var/cache/apt,rw,sharing=private --mount=type=cache,target=/var/lib/apt,rw,sharing=private  \
  apt update && \
  apt install -y --no-install-recommends \
  build-essential \
  bash \
  curl \
  g++ \
  lsb-release \
  wget \
  cmake \
  libssl-dev \
  pkg-config \
  software-properties-common \
  ca-certificates \
  git \
  sudo \
  && rm -rf /var/lib/apt/lists/*

# Add `dev` so that we're not developing as the `root` user
RUN useradd dev \
  --create-home \
  --shell=/bin/bash \
  --uid=1001 \
  --user-group && \
  mkdir -p /etc/sudoers.d && \
  echo "dev ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER dev
WORKDIR /home/dev

# Install newer GCC and libstdc++6
RUN --mount=type=cache,target=/var/cache/apt,rw,sharing=private --mount=type=cache,target=/var/lib/apt,rw,sharing=private  \
  sudo apt update && \
  sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
  sudo apt install -y --no-install-recommends gcc-12 g++-12 libstdc++6 && \
  sudo rm -rf /var/lib/apt/lists/*

# Set gcc-12 as default
RUN sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100 --slave /usr/bin/g++ g++ /usr/bin/g++-12

ENV CARGO_HOME=/cargo
ENV RUSTUP_HOME=/cargo
ENV CARGO_TARGET_DIR=/cargo/target
ENV PATH=${CARGO_HOME}/bin:$PATH

# Install rust
RUN sudo mkdir -p $CARGO_HOME && \
    sudo chown -R dev:dev $CARGO_HOME && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain 1.88.0 && \
    rustup component add rust-analyzer && \
    cargo install --locked cargo-chef sccache

# Install whichever Node version is LTS (and yarn)
RUN curl -sL https://deb.nodesource.com/setup_lts.x | sudo bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Install tesseract apt repository
RUN sudo add-apt-repository -y ppa:alex-p/tesseract-ocr-devel
# Install deadsnakes apt repository
RUN sudo add-apt-repository -y ppa:deadsnakes/ppa

# Install other dependencies
RUN --mount=type=cache,target=/var/cache/apt,rw,sharing=private --mount=type=cache,target=/var/lib/apt,rw,sharing=private  \
  sudo apt-get update && \
  sudo apt-get install -y --no-install-recommends \
  libpq-dev \
  postgresql \
  postgresql-contrib \
  python3-dev \
  python3.11 \
  python3.11-dev \
  python3.11-venv \
  jq \
  locales \
  nodejs \
  yarn \
  socat \
  apt-transport-https \
  unzip \
  autossh \
  && sudo rm -rf /var/lib/apt/lists/*

# Set up Python 3.11 in /usr/local
RUN sudo mkdir -p /usr/local/python3.11/bin && \
  sudo ln -s /usr/bin/python3.11 /usr/local/python3.11/bin/python && \
  sudo ln -s /usr/bin/python3.11 /usr/local/python3.11/bin/python3

# Install neovim
RUN curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && \
  sudo rm -rf /opt/nvim && \
  sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Add python, neovim to path
ENV PATH=/usr/local/python3.11/bin:/opt/nvim-linux-x86_64/bin:$PATH

# install protoc
RUN set -eux; \
ARCH=$(uname -m); \
case "$ARCH" in \
  x86_64) PROTOC_ZIP=protoc-31.1-linux-x86_64.zip ;; \
  aarch64) PROTOC_ZIP=protoc-31.1-linux-aarch_64.zip ;; \
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;; \
esac; \
curl -OL "https://github.com/protocolbuffers/protobuf/releases/download/v31.1/$PROTOC_ZIP"; \
sudo unzip -o "$PROTOC_ZIP" -d /usr/local bin/protoc; \
sudo unzip -o "$PROTOC_ZIP" -d /usr/local 'include/*'; \
rm -f "$PROTOC_ZIP"; \
protoc --version

# Install vacuum
RUN sudo chown -R dev:dev /usr/local/bin /usr/local/lib /usr/local/include /usr/local/share /usr/local/etc
RUN curl -fsSL https://quobix.com/scripts/install_vacuum.sh | sh

# Generate the desired locale (en_US.UTF-8)
RUN sudo locale-gen en_US.UTF-8

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install sources
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget libpq-dev postgresql -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list \
  && sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

# install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  chmod +x kubectl && \
  sudo mv ./kubectl /usr/local/bin

# Install starship
RUN curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes --bin-dir /usr/local/bin

# Install ripgrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.0/ripgrep_14.1.0-1_amd64.deb && \ 
  sudo dpkg -i ripgrep_14.1.0-1_amd64.deb && \
  rm ripgrep_14.1.0-1_amd64.deb

# Install zoxide
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir /usr/local/bin

# Install fzf
RUN curl -LO https://github.com/junegunn/fzf/releases/download/v0.59.0/fzf-0.59.0-linux_amd64.tar.gz && \
  sudo tar -xvzf fzf-0.59.0-linux_amd64.tar.gz -C /usr/local/bin && \
  rm fzf-0.59.0-linux_amd64.tar.gz

RUN sudo apt update && sudo apt install -y zsh gh git-lfs eza && git lfs install

RUN sudo chsh -s $(which zsh) $(whoami)

# Install atuin
RUN curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh && \
  sudo mv ~/.atuin/bin/* /usr/local/bin

# Install depot
RUN curl -L https://depot.dev/install-cli.sh | sh && sudo mv /home/dev/.depot/bin/depot /usr/local/bin

# Install the docker cli
ENV DOCKERVERSION=27.5.1
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && sudo tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
  -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

# Install helm 
RUN curl -fsSLO https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz \ 
  && sudo tar xvzf helm-v3.17.0-linux-amd64.tar.gz --strip 1 -C /usr/local/bin linux-amd64/helm \
  && rm helm-v3.17.0-linux-amd64.tar.gz

# k9s
RUN curl -fsSLO https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz \ 
  && sudo tar xvzf k9s_Linux_amd64.tar.gz -C /usr/local/bin k9s \
  && rm k9s_Linux_amd64.tar.gz

# skaffold
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
  sudo install skaffold /usr/local/bin/ && \
  rm skaffold

# Install openssh-server for reverse SSH tunnels
RUN sudo apt update && \
  sudo apt install -y openssh-server openssh-client && \
  sudo mkdir -p /var/run/sshd && \
  sudo mkdir -p /home/dev/.ssh && \
  sudo chown dev:dev /home/dev/.ssh && \
  sudo chmod 700 /home/dev/.ssh && \
  sudo rm -rf /var/lib/apt/lists/*

# Configure SSH for reverse tunnels
RUN sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
  sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
  sudo sed -i 's/#GatewayPorts no/GatewayPorts yes/' /etc/ssh/sshd_config && \
  sudo sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/' /etc/ssh/sshd_config

ENV HF_ENDPOINT=http://mirror-hf-mirror-local
ENV SHELL=/usr/bin/zsh
