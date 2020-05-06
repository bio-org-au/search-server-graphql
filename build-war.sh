#!/bin/bash

if [ $1 = "setup" ]; then
  . ./setup-dev-linux.sh
fi

export JAVA_OPTS='-server -d64'

rm *.war || echo "no war files"

echo "which jruby"
which jruby

echo PATH:- $PATH

echo "java -version"
java -version

echo "jruby -v"
jruby -v

jruby -S bundle config set without 'development test'
jruby -S bundle config set deployment 'true'
jruby -S bundle install

echo "** compile assets"
jruby -S bundle exec rake assets:clobber RAILS_ENV=production
jruby -S bundle exec rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets

echo "** create war"
jruby -S bundle exec warble RAILS_ENV=production

