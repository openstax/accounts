FROM ruby:2.5.0

WORKDIR /code

COPY Gemfile Gemfile.lock ./

ENV BUNDLE_PATH="/bundle_cache"\
        BUNDLE_BIN="/bundle_cache/bin"\
        BUNDLE_APP_CONFIG="/bundle_cache"\
        GEM_HOME="/bundle_cache"\
        PATH=/bundle_cache/bin:/bundle_cache/gems/bin:$PATH\
        PORT=2999

# BRYAN - I WASN'T UPDATING RIGHT, SEE: https://bundler.io/v2.0/guides/bundler_2_upgrade.html
# RUN gem update --system \
#          && gem install bundler --version '2.0.1' --install-dir /bundle_cache --bindir /bundle_cache/bin --no-user-install \
#          && bundle _2.0.1_ install --without production --path /bundle_cache

RUN bundle install --without production --path /bundle_cache

EXPOSE 2999

CMD ["bundle", "exec", "rails", "server", "--binding", "0.0.0.0"]
