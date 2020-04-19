ARG ZLIB_VERSION=1:1.2.11.dfsg-1
ARG CA_CERTIFICATES_VERSION=20190110
ARG GNUPG_VERSION=2.2.12-1+deb10u1
ARG BUILD_ESSENTIAL_VERSION=12.6

FROM debian:10.3-slim as buster
FROM buster as ruby-install

ARG ZLIB_VERSION
ARG CA_CERTIFICATES_VERSION
ARG GNUPG_VERSION
ARG BUILD_ESSENTIAL_VERSION

ARG LIBFFI_VERSION=3.2.1-9
ARG CURL_VERSION=7.64.0-4+deb10u1
ARG CA_CERTIFICATES_VERSION=20190110
ARG OPENSSL_VERSION=1.1.1d-0+deb10u2
ARG READLINE_VERSION=7.0-5

ARG RUBY_MINOR_VERSION=2.6
ARG RUBY_VERSION=2.6.6
ARG RUBY_BUILD_VERSION=20200401
ARG RUBYGEMS_VERSION=3.1.2
ARG BUNDLER_VERSION=2.1.4

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN set -eux; \
    apt update; \
    apt install -y --no-install-recommends \
      build-essential=${BUILD_ESSENTIAL_VERSION} \
      libffi-dev=${LIBFFI_VERSION} \
      zlib1g-dev=${ZLIB_VERSION} \
      curl=${CURL_VERSION} \
      ca-certificates=${CA_CERTIFICATES_VERSION} \
      libssl-dev=${OPENSSL_VERSION} \
      libreadline-dev=${READLINE_VERSION}; \
    rm -rf /var/lib/apt/lists/*

# Set environment
ENV PATH=/usr/local/ruby/bin:$PATH

#Install ruby
RUN set -eux; \
    export RUBY_INSTALL_PATH=/usr/local/ruby; \
    \
    # Install ruby-build tool
    curl -L https://github.com/rbenv/ruby-build/archive/v${RUBY_BUILD_VERSION}.tar.gz -o ruby-build.tar.gz && \
      tar -xzf ruby-build.tar.gz && \
      ./ruby-build-${RUBY_BUILD_VERSION}/install.sh && \
      rm -r ruby-build.tar.gz ruby-build-${RUBY_BUILD_VERSION}; \
    \
    # Install ruby
    TMPDIR=/tmp CONFIGURE_OPTS="--disable-install-doc" \
      ruby-build ${RUBY_VERSION} ${RUBY_INSTALL_PATH}; \
    \
    # Don't install documents
    mkdir ${RUBY_INSTALL_PATH}/etc && \
      echo "install: --no-document" >> ${RUBY_INSTALL_PATH}/etc/gemrc && \
      echo "update: --no-document" >> ${RUBY_INSTALL_PATH}/etc/gemrc; \
    \
    # Update rubygems version
    gem update --system ${RUBYGEMS_VERSION} && \
      gem uninstall rubygems-update --executables; \
    # Install bundler
    gem install --no-document --force bundler -v ${BUNDLER_VERSION}; \
    \
    # Clean
    rm -rf \
      /tmp/* \
      /usr/local/bin/* \
      /usr/local/share/ruby-build \
      /root/.gem \
      /usr/local/ruby/lib/ruby/gems/${RUBY_MINOR_VERSION}.0/cache/*;

FROM buster

ARG BUILD_ESSENTIAL_VERSION
ARG ZLIB_VERSION
ARG CA_CERTIFICATES_VERSION
ARG GNUPG_VERSION

ARG DEBIAN_FRONTEND=noninteractive

# Set environment
ENV PATH=/usr/local/ruby/bin:$PATH

# Silence bundler root warning
ENV BUNDLE_SILENCE_ROOT_WARNING=1

# Install some essential system libs
RUN set -eux; \
    apt update; \
    apt install -y --no-install-recommends \
      build-essential=${BUILD_ESSENTIAL_VERSION} \
      zlib1g-dev=${ZLIB_VERSION} \
      ca-certificates=${CA_CERTIFICATES_VERSION} \
      gnupg2=${GNUPG_VERSION}; \
    rm -rf /var/lib/apt/lists/* /tmp/*

COPY --from=ruby-install /usr/local/ruby /usr/local/ruby
