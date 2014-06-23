# Daylight

Daylight extends Rails and ActiveResource to allow your client API to perform
akin to ActiveRecord

Features include those like ActiveRecord such as scopes, `find_by` lookups,
calling associations on  server-side models, using through associations, and
the ability to chain queries.  Eases requesting complex queries on your Rails
models using `remoted` methods.

Typical ActiveResource functionality:

  ````ruby
  API::Post.all                                      # index request
  API::Post.published                                # client-based association
  API::Post.find(1)                                  # show request
  ````

Daylight adds to ActiveResource with chained queries:

  ````ruby
  API::Post.where(author_id: 1)                      # simple query
  API::Post.where(author_id: 1).first                # chained query
  API::Post.where(author_id: 1).published            # chained query with scope
  API::Post.where(author_id: 1).published.recent     # chained query with multiple scopes
  API::Post.where(author_id: 1).limit(10).offset(20) # chained query with limit and offset
  API::Post.where(author_id: 1).order(:date)         # chained query with ordering

  API::Post.find_by(slug: '100-best-albums-2014')    # find_by lookup gets first match
  ````

Daylight can also chain queries on an ActiveResource's association.  All of the
chain queries above can be used to refine searches on associations:

  ````ruby
  API::Post.first.comments                           # lookup and association
  API::Post.first.comments.where(user_id: 2)         # query on lookup's association
  API::Post.first.comments.where(user_id: 2).first   # chained query on
  API::Post.first.comments.where(user_id: 2).edited  # chained query with scope
                                                     # etc.
  ````

Daylight allows you to return collections from complex queries on your model:

  ````ruby
  API::Post.first.top_comments
  ````

Daylight packages API query details in one request when it can to lower
the network overhead.

Daylight allows you to query for a record before initializing or creating it
using ActiveRecord's familiar `first_or_create` and `first_or_initialize`
methods.

  ````ruby
  post = API::Post.new(slug: '100-best-albums-2014')
  post.author = API::User.find_or_create(username: 'reidmix')
  post.save
  ````

The last query to the database uses Rails' `accepts_nested_attributes_for`
and the `User` could have easily been setup with `find_or_initialize` to
reduce the number of server-side queries.

More information can be found in the [Daylight Users Guide](doc/guide.md).

## Getting Started

1. Install Daylight both on your server and your client.

        gem install daylight

2. On your server, add a rails initializer:

    ````ruby
    require 'daylight/server'
    ````

3. On your client, setup your API:

    ````ruby
    Daylight::API.setup!(endpoint: 'http://localhost/')
    ````

4. Use your client models to query your API!

## Development

Ah, but we have to develop our API and client models:

1. Develop your Rails models, controllers, and routes like you do today.  Add
   a serializer for each model in the API.  Daylight provides additions to
   simplify adding features to your controllers and routes.

2. Develop your client models using Daylight's extensions to ActiveResource.
   Daylight provides Mocks to aid in full stack testing of your client models.

3. Consider versioning your client models and distribute them using a gem.
   Daylight supports versioned APIs and has facilities available for your
   development.

4. More information can be found on:
    * [Installation Steps](doc/install.md)
    * [Daylight Users Guide](doc/usage.md)
    * [API Developer Guide](doc/develop.md)
    * [Testing Your API](doc/testing.md)
    * [How to Contribute](doc/contribute.md)

## License

Daylight is released under the [Apache License](http://www.apache.org/licenses/LICENSE-2.0).
