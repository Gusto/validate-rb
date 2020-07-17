ARG ruby=2.6.6

FROM ruby:$ruby as build

WORKDIR /app

RUN gem install bundler -v '2.1.4'
RUN bundle config set path 'vendor/'

COPY Gemfile *.gemspec /app/
COPY lib/ /app/lib
RUN bundle install

FROM ruby:$ruby-slim

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git; \
    git config --global user.email "no-reply@github.com"; \
    git config --global user.name "Github Workflow"

WORKDIR /app

COPY --from=build /root /root
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
COPY . /app

ENTRYPOINT ["bundle", "exec"]
