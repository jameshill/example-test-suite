FROM ruby:2.7-alpine

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
RUN gem install bundler -v 2.4.22
RUN bundle install

# Copy the rest of the application code
COPY . .

# Set entrypoint
ENTRYPOINT ["bundle", "exec"]
