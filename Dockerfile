FROM ruby:2.3.3

WORKDIR /code

COPY Gemfile Gemfile.lock ./

RUN bundle install --without production

EXPOSE 2999

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
