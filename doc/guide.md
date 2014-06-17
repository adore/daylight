# Daylight Users Guide

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

