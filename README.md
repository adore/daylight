# Daylight

Daylight extends Rails and ActiveResource to allow your client API to perform
akin to ActiveRecord

Features include those like ActiveRecord such as scopes, `find_by` lookups,
calling server-side associations, through associations, and the ability to
chain queries.  Also, eases calling complex queries on your Rails models.

    API::Post.all                                      # ActiveResource request
    API::Post.published                                # server-side association

    API::Post.where(author_id: 1)                      # ActiveResource query
    API::Post.where(author_id: 1).published            # chained query and scope
    API::Post.where(author_id: 1).first                # chained query
    API::Post.where(author_id: 1).limit(10).offset(20) # chained query with limit and offset
    API::Post.where(author_id: 1).order(:date)         # chained query with ordering

    API::Post.find_by(slug: '100-best-albums-2014')    # find_by lookup gets first match

    API::Post.find(1).comments                         # lookup and association
    API::Post.find(1).comments.where(user_id: 2)       # query on lookup's association
    API::Post.find(1).comments.where(user_id: 2).first # chained query on lookup's association

    API::Post.by_popularity                            # complex query called remotely

More information about all of Daylight's possiblities can be found in the
[Developer Guide](doc/guide.md).

Daylight packages API query details in one request when it can to lower
the network overhead.  Obvious exception being Daylight's `first_or_create` and
`first_or_initialize` where the lookups occur befure updates.

    post = API::Post.new(slug: '100-best-albums-2014')
    post.author = API::User.find_or_create(username: 'reidmix')
    post.save

Here, there are 4 queries to the server:
1. To lookup a `User` with the username 'reidmix'
2. The creation of the `User` with the username 'reidmix'
3. Save the `Post` and associate the newly created `User`

The last query to the database uses Rails' `accepts_nested_attributes_for`
and the `User` could have easily been setup with `find_or_initialize` to
reduce the number of server-side queries to 2.




1. More information can be found on:
    * [Getting Started](doc/install.md)
    * [Developer Guide](doc/guide.md)
    * [Testing Your API](doc/testing.md)
    * [Guiding Principles](doc/principles.md)
