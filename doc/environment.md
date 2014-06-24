# Build Environment

This is the environment that Daylight was built with that may not be obvious
simply from the Gemfile.

## Requirements

Only items requrired are [ruby](https://www.ruby-lang.org/en/downloads/)
and [bundler](http://bundler.io/) to contribute to Daylight.

All other [dependencies](#dependencies) are loaded via `bundler`.

    ruby                      2.0.0-p247
    bundler                   1.3.5

## Developers Preferences

We use [rbenv](https://github.com/sstephenson/rbenv) to help manage
our ruby versions and [pow](http://pow.cx/) as our application
(rack) server.  YMMV, and can use any tool to handle these functions.

    rbenv                      0.4.0
    pow                        0.4.1
    powder                     0.2.0

FWIW, we also use rbenv plugin
[rbenv-gemset](https://github.com/jf/rbenv-gemset),
[rbenv-bundler](https://github.com/carsomyr/rbenv-bundler), and
[rbenv-gem-rehash](https://github.com/sstephenson/rbenv-gem-rehash)

We control pow using the [powder](https://github.com/Rodreegez/powder) CLI.

## Runtime Dependencies

    rails                      4.0.5
    activeresource             4.0.0
    active_model_serializers   0.8.1

[Rails](https://github.com/rails/rails)) and
[ActiveModelSerializers](https://github.com/rails-api/active_model_serializers)
are required by Daylight run the server and extend it.
[ActiveResource](https://github.com/rails/activeresource) is required by Daylight to run the client and extend it.

    haml                       4.0.5
    hanna-bootstrap            0.0.5
    actionpack-page_caching    1.0.2

These are for the Documentation Rails Engine.
[Haml](https://github.com/haml/haml) is a
templating engine to generate the API documentation.
[actionpack-page_caching](https://github.com/rails/actionpack-page_caching)
will cache the generated documenation so there is no penalty to the server.

[hanna-bootstrap](https://github.com/ngs/hanna-bootstrap) to generate
rdoc using the twitter bootstrap theme.

## Development & Test Dependencies

    rspec                      2.14.1
    rspec-rails                2.14.2
    simplecov-rcov             0.2.3

We use [rspec](https://github.com/rspec/rspec) and
[rspec-rails](https://github.com/rspec/rspec-rails)
for rails testing and
[simplecov-rcov](https://github.com/fguillen/simplecov-rcov)
for coverage testing.

    webmock                    1.18.0

Daylight request and responses occur through [webmock](https://github.com/bblimke/webmock).
`Daylight::Mock` is built on top of it.

    sqlite3-ruby               1.3.9
    factory_girl               2.0
    faker                      1.2.0

Database backend is handled by [sqlite3](https://github.com/sparklemotion/sqlite3-ruby),
you will need to [download](https://www.sqlite.org/download.html)
the binaries or use your favorite package manager.

  ````
    brew install sqlite3
  ````

We use [factory_girl](https://github.com/thoughtbot/factory_girl)
to build our fixtures and [faker](https://github.com/stympy/faker)
to populate its data.
