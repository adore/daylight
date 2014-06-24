# Build Environment

This is the environment that Daylight was built with that may not be obvious
simply from the Gemfile.

## Requirements

Only items requrired are `ruby` and `bundler` to contribute to Daylight.
All other [dependencies](#dependencies) are loaded via bundler.

    ruby                      2.0.0-p247   [Download](https://www.ruby-lang.org/en/downloads/)
    bundler                   1.3.5        [Homepage](http://bundler.io/)

## Developers Preferences

We use `rbenv` to help manage our ruby versions and `pow` as our application
(rack) server.  YMMV, and can use any tool to handle these functions.

    rbenv                      0.4.0        [Github](https://github.com/sstephenson/rbenv)
    pow                        0.4.1        [Homepage](http://pow.cx/)
    powder                     0.2.0        [Github](https://github.com/Rodreegez/powder)

FWIW, we also use rbenv plugin
[rbenv-gemset](https://github.com/jf/rbenv-gemset),
[rbenv-bundler](https://github.com/carsomyr/rbenv-bundler), and
[rbenv-gem-rehash](https://github.com/sstephenson/rbenv-gem-rehash)

We control pow using the powder CLI.

## Runtime Dependencies

    rails                      4.0.5        [Github](https://github.com/rails/rails)
    activeresource             4.0.0        [Github](https://github.com/rails/activeresource)
    active_model_serializers   0.8.1        [Github](https://github.com/rails-api/active_model_serializers)

Rails and `ActiveModelSerializers` are required by Daylight run the server and extend it.
`ActiveResource` is required by Daylight to run the client and extend it.

    haml                       4.0.5        [Github](https://github.com/haml/haml)
    hanna-bootstrap            0.0.5        [Github][https://github.com/ngs/hanna-bootstrap]
    actionpack-page_caching    1.0.2        [Github](https://github.com/rails/actionpack-page_caching)

These are for the Documentation Rails Engine.  [Haml](haml.info) is a
templating engine to generate the API documentation.

[hanna-bootstrap](https://github.com/ngs/hanna-bootstrap) to generate
rdoc using the twitter bootstrap theme.

## Development & Test Dependencies

    rspec                      2.14.1       [Github](https://github.com/rspec/rspec)
    rspec-rails                2.14.2       [Github](https://github.com/rspec/rspec-rails)
    simplecov-rcov             0.2.3        [Github](https://github.com/fguillen/simplecov-rcov)

We use [rspec](https://www.relishapp.com/rspec/) and
[rspec-rails](https://www.relishapp.com/rspec/rspec-rails/docs)
for rails testing and simplecov-rcov for coverage testing.

    webmock                    1.18.0       [Github](https://github.com/bblimke/webmock)

Daylight request and responses occur through webmock.
`Daylight::Mock` is built on top of it.

    sqlite3-ruby               1.3.9        [Github](https://github.com/sparklemotion/sqlite3-ruby)
    factory_girl               2.0          [Github](https://github.com/thoughtbot/factory_girl)
    faker                      1.2.0        [Github](https://github.com/stympy/faker)

Database backend is handled by [sqlite3](https://www.sqlite.org/),
you will need to [download](https://www.sqlite.org/download.html)
the binaries or use your favorite package manager.

    ````
      brew install sqlite3
    ````

We use factory_girl to build our fixtures and faker to populate its data.
