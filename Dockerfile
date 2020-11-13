FROM ruby:2.6.3

WORKDIR /code

COPY Gemfile Gemfile.lock ./

ENV BUNDLE_PATH="/bundle_cache"\
        BUNDLE_BIN="/bundle_cache/bin"\
        BUNDLE_APP_CONFIG="/bundle_cache"\
        GEM_HOME="/bundle_cache"\
        PATH=/bundle_cache/bin:/bundle_cache/gems/bin:$PATH\
        PORT=2999

RUN gem install bundler:2.1.4 && \
    bundle config set path '/bundle_cache' && \
    bundle config set without 'production' && \
    bundle _2.1.4_ install

EXPOSE 2999

CMD ["bundle", "exec", "rails", "server", "--binding", "0.0.0.0", "--port", "2999"]
