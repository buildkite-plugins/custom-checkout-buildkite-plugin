FROM buildkite/plugin-tester:v4.2.0

# Install dependencies
RUN apk update && \
    apk add --no-cache \
    bash \
    git \
    openssh-client \
    curl \
    ca-certificates \
    openssl

# Install bats-core from GitHub
RUN mkdir -p /tmp/bats && \
    git clone https://github.com/bats-core/bats-core.git /tmp/bats/bats-core && \
    /tmp/bats/bats-core/install.sh /usr/local && \
    rm -rf /tmp/bats

WORKDIR /plugin

COPY . /plugin

ENTRYPOINT ["bash"]
