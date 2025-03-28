FROM ruby:3.3-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    git \
    curl

# test-engine-client
COPY --from=buildkite/test-engine-client:v1.3.2 /usr/local/bin/bktec /usr/local/bin/bktec

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN gem install bundler
RUN bundle install

# Copy the rest of the application code
COPY . .

# Set entrypoint
ENTRYPOINT ["bundle", "exec"]
