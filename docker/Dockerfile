ARG ruby=2.6.6

FROM ruby:$ruby as build

WORKDIR /app

RUN gem install bundler -v '2.1.4'
RUN bundle config set path 'vendor/'

COPY Gemfile *.gemspec /app/
COPY lib/ /app/lib
RUN bundle install

FROM ruby:$ruby-alpine

RUN apk update && apk add --no-cache git

WORKDIR /app

COPY --from=build /root /root
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
COPY . /app

ENTRYPOINT ["bundle", "exec"]
