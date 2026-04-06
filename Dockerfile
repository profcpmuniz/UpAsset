# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t up_asset .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name up_asset up_asset

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment variables and enable jemalloc for reduced memory usage and latency.
ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3 --path "${BUNDLE_PATH}" --without development && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Create a helper entrypoint script while still running as root in the build stage
RUN printf '%s\n' '#!/bin/sh' 'if [ -z "$SECRET_KEY_BASE" ]; then' '  export SECRET_KEY_BASE=$(bundle exec rails secret)' 'fi' 'exec "$@"' > /tmp/docker-entrypoint.sh && \
    chmod +x /tmp/docker-entrypoint.sh

# Final stage for app image
FROM base

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --gid 1000 --create-home --shell /bin/bash

# Copy built artifacts: gems, application, and the helper entrypoint
COPY --chown=rails:rails --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=build /rails /rails
COPY --chown=rails:rails --from=build /tmp/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Ensure runtime directories exist and are owned by the non-root rails user
RUN mkdir -p /rails/tmp /rails/log && \
    chown -R rails:rails /rails/tmp /rails/log /usr/local/bin/docker-entrypoint.sh

USER 1000:1000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Start Rails server by default on port 3000
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
