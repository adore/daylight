# Daylight Users Guide


## `accepts_nested_attributes_for`

If your model `accepts_nested_attributes_for` on the `blog` association, you
may re-associate it:

  ````ruby
    post = Daylight::Post.first

    post.blog.id #=> 1
    post.blog = API::Blog.find(2)
    post.save    #=> true

    post = Daylight::Post.first
    post.blog.id #=> 2
  ````


> NOTE: There is alignment with `has_one :through` built in Daylight to match
> Rails way of doing things.

You can chain `accepts_nested_attributes_for` to update these
`has_one :through` associations.  For example, if both:
* `Post` `accepts_nested_attributes_for :blog`
* `Blog` `accepts_nested_attributes_for :company`
Then you can re-associate the  `Company` on the `Post` itself:

  ````ruby
    post = Daylight::Post.first

    post.blog.id #=> 1
    post.company = API::Company.find(3)
    post.save    #=> true

    post = Daylight::Post.first
    post.company.id #=> 2
  ````

> FUTURE [#5](https://github.com/att-cloud/daylight/issues/5):
> Updates on the `has_one` and `belongs_to` association do not get propagated
> and should be.  Currently, only re-associations are propagated.

Saving the parent class doesn't save updates to the associations.  You can
save these associated instances directly:

  ````ruby
    post = Daylight::Post.first
    post.blog.name #=> "My Blog"
    post.blog.name = "Reidmix"
    post.blog.save #=> true

    post = Daylight::Post.first
    post.blog.name #=> "Reidmix"
  ````

## Optimizations

### Understanding Payload Size

### Understanding Request Frequency

From our example on in the [README](../README.doc) we show creating a `Post`
and `User` and associating the two:

    post = API::Post.new(slug: '100-best-albums-2014')
    post.author = API::User.find_or_create(username: 'reidmix')
    post.save

There are 3 queries to the server:

1. To lookup a `User` with the username 'reidmix'
2. The creation of the `User` with the username 'reidmix'
3. Save the `Post` and associate the newly created `User`

