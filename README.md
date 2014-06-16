# Daylight

Daylight extends Rails and ActiveResource to allow your client API to perform
akin to ActiveRecord

Features include those like ActiveRecord such as scopes, `find_by` lookups,
calling server-side associations, using through associations, and the ability
to chain queries.  Eases requesting complex queries on your Rails models
through `remoted` methods.

Typical ActiveResource functionality:

    API::Post.all                                      # index request
    API::Post.published                                # client-based association
    API::Post.find(1)                                  # show request

Daylight adds to ActiveResource with chained queries:

    API::Post.where(author_id: 1)                      # simple query
    API::Post.where(author_id: 1).first                # chained query
    API::Post.where(author_id: 1).published            # chained query with scope
    API::Post.where(author_id: 1).published.recent     # chained query with multiple scopes
    API::Post.where(author_id: 1).limit(10).offset(20) # chained query with limit and offset
    API::Post.where(author_id: 1).order(:date)         # chained query with ordering

    API::Post.find_by(slug: '100-best-albums-2014')    # find_by lookup gets first match

Daylight can also chain queries on an ActiveResource's association.  All of the
chain queries above can be used to refine searches on associations:

    API::Post.first.comments                           # lookup and association
    API::Post.first.comments.where(user_id: 2)         # query on lookup's association
    API::Post.first.comments.where(user_id: 2).first   # chained query on
    API::Post.first.comments.where(user_id: 2).edited  # chained query with scope
                                                       # etc.

Daylight allows you to return collections from complex queries on your model:

    API::Post.by_popularity                            # complex query called remotely

Daylight packages API query details in one request when it can to lower
the network overhead.  More information can be found in the [Developer Guide](doc/guide.md).


Daylight allows you to query for a record before initializing or creating it
using ActiveRecord's familiar `first_or_create` and `first_or_initialize`
methods.

    post = API::Post.new(slug: '100-best-albums-2014')
    post.author = API::User.find_or_create(username: 'reidmix')
    post.save

The last query to the database uses Rails' `accepts_nested_attributes_for`
and the `User` could have easily been setup with `find_or_initialize` to
reduce the number of server-side queries.

## Getting Started




1. More information can be found on:
    * [Installation Steps](doc/install.md)
    * [Developer Guide](doc/guide.md)
    * [Testing Your API](doc/testing.md)
    * [Guiding Principles](doc/principles.md)
