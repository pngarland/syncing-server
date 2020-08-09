FROM ruby:2.6.5-alpine AS build-env

RUN apk update \
  && apk upgrade

ARG RAILS_ROOT=/app
ARG BUILD_PACKAGES="build-base curl-dev git"
ARG DEV_PACKAGES="postgresql-dev yaml-dev zlib-dev"
ARG RUBY_PACKAGES="tzdata"

ENV RAILS_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

WORKDIR $RAILS_ROOT
# install packages
RUN apk add --update --no-cache \
  $BUILD_PACKAGES \
  $DEV_PACKAGES \
  $RUBY_PACKAGES

COPY Gemfile* ./
RUN gem install bundler \
  && bundle config --global frozen 1 \
  && bundle config set without 'development test docker_development' \
  && bundle install \
    --path=vendor/bundle

COPY . .

############### Build step done ###############
FROM ruby:2.6.5-alpine

ARG RAILS_ROOT=/app
ARG PACKAGES="tzdata postgresql-client"

ENV RAILS_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"

WORKDIR $RAILS_ROOT
# install packages
RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache $PACKAGES \
    && gem install bundler

COPY --from=build-env $RAILS_ROOT $RAILS_ROOT
EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
