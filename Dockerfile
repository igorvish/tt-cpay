FROM ruby:2.4.1-jessie

ENV LANG C.UTF-8
ENV APP_HOME /var/www/tt-cpay

WORKDIR $APP_HOME

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  libxml2-dev libxslt1-dev \
  nodejs \
  libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile* $APP_HOME/
RUN gem install bundler && bundle install --without `#development` test --jobs 4 --retry 5
COPY . $APP_HOME

EXPOSE 3000

CMD ["sh", "-c", "rails s --help"]
