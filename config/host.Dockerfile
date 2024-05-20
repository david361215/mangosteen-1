FROM ruby:3.0.0

ENV RAILS_ENV production
RUN mkdir /mangosteen
RUN bundle config mirror.https://rubygems.org https://gems.ruby-china.com
WORKDIR /mangosteen
ADD Gemfile /mangosteen
ADD Gemfile.lock /mangosteen
ADD vendor/cache.tar.gz /mangosteen/vendor/
ADD vendor/rspec_api_documentation.tar.gz /mangosteen/vendor/ 
RUN bundle config set --local without 'development test'
RUN bundle install

ADD mangosteen-*.tar.gz ./
ENTRYPOINT bundle exec puma

# FROM ruby:3.0.0
# ENV RAILS_ENV production
# RUN mkdir /mangosteen
# RUN bundle config mirror.https://rubygems.org https://gems.ruby-china.com
# WORKDIR /mangosteen
# ADD mangosteen-*.tar.gz ./

# RUN bundle config set --local without 'development test'
# RUN bundle install

# ENTRYPOINT bundle exec puma