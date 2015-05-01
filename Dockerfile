FROM ruby:2.1
MAINTAINER Vincent Demeester <vincent@sbr.pm>

RUN apt-get -y update && \
    apt-get -y install nodejs locales
RUN locale-gen en_US.UTF-8

RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle install

ONBUILD COPY . /usr/src/app

CMD bundle exec jekyll serve --watch
