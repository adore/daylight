# API Developer Guide

Daylight uses the MVC model provided by Rails to divide labor of an API request
with some constraints.

Instead of views, serializers are used to generate JSON/XML.  Routes have a
great importance to the definition of the API.  And the client becomes the
remote proxy for all API requests.

To better undertand Daylight's interactions, we define the following components:
* Rails **model** is the canonical version of the object
* A **serializer** defines what parts of the model are exposed to the client
* Rails **controller** defines which actions are performed on the model
* Rails **routes** defines what APIs are available to the client
* The **client** model is the remote representation of the Rails model

Table of Contents:
* [Expectations](#expectations)
* [Building Your API](#building-api)
  * [Models](#models)
  * [Controllers](#controllers)
  * [Serializers](#serializers)
  * [Routes](#routes)
  * [Client](#client)
* [Underlying Interaction](#interaction)
  * [Symantic URLs](#symantic-urls)
  * [Request Params](#request-params)
  * [Symantic Data](#symantic-data)
  * [Response Metadata](#metadata)
* [Framework Links](#framework)

<a id="Expectations"></a>
## Expectations

* **Rails 4**: Daylight was built only using the most current version of Rails 4
* **Versioned APIs**: APIs will be versioned, at the least with `v1` as the current and only version
* **ActiveModelSerializer**: Serialization occurs via `ActiveModel::Serailizer`, typically in JSON

<a id="building-api"></a>
## Building Your API

Building your Client from the bottom up you will need to develop your models,
controllers, routes that you are familiar with today.  Add serializers to
describe the JSON generation of your object.  Finally, build your client models
based on the API actions available and the response from the server.

<a id="models"></a>
### Models

Models are built exactly as they are in Rails, no changes are neccessary.

Through specifiecation on the routes, Daylight allows you to make scopes and
methods available to the client.

> Note: Daylight expects an model object or a collection when parsing results
> from a model method.

You can chose to allow models to be created, updated, and associated through
a "parent" model using the `accepts_nested_attributes_for` mechansism.

      class Post < ActiveRecord::Base
        has_many :comments

        accepts_nested_attributes_for :comments
      end

Once the client is setup you can do the following:

    post = API::Post.find(1)
    post << API::Comment.new(text: "This is an awesome post")
    post.save

> Note: ActiveResource looks up associations using foriegn keys but with
> Daylight you can call the associations defined on your model directly.

This is especially useful when you wish to preserve the richness of options on
your associations that are neccessary for your application to function
correctly.  For example:

    class Post
      has_many :comments
      has_many :author, foreign_key: 'created_by_user_id', class_name: 'User'
      has_many :commenters, -> { uniq }, through: :comments, class_name: 'User'
      has_many :suppressed_comments, -> { where(spam: true) }, class_name: 'Comment'
    end

Here we have 4 examples where using the model associations are neccesary.  When
there is:

1. A configured foreign_key as in `author`
2. A through association as in `commenters`
3. A condindition block as `commenters` and `suppressed_comments` (eg. `uniq`
   and `where`)
4. A class_name in all three `author`, `commenters`, and `suppressed_comments`

ActiveResource will not be able to resolve these options without using the
model-associations, because it:
* Cannot determine endpoint or correct class to instanciate
* Uses the wrong lookup key (in through associations and foreign key option)
* Conditions will not be supplied in the request

> Note: Daylight includes Daylight::Refiners on all models that inheret from
> ActiveRecord::Base.  At this time there is no way to exclude models.

<a id="controllers"></a>
### Controllers

Controllers can be written without Daylight, but often times you must develop
boilerplate code for index, create, show, update, and delete actions.  Also,
you may chose controllers that are for the API and controllers that are for
your application.

Daylight simplifies building API controllers:

    class PostController < APIController
    end

> Note: Any functionality built in `ApplicationController` will be available to
> your `APIController` subclasses.

You must "turn on" REST actions to allow for functionality.  All actions
provided by Daylight are turned off by default so what is exposed is determined
by the developer.

For example, to turn on `show` action:

    class PostController < APIController
      handles :show
    end

This is equivalent to;

    class PostController < APIController
      def show
        render json: Post.find(params[:id])
      end
    end

Daylight uses the name of the controller to determine the related model to use.
Also, the `primary_key` name is retrived from that determined model.  In fact,
all of the actions are just ruby methods, so you can overwrite them (and call
super) as you see fit:

    class PostController < APIController
      handles :show

      def show
        @blog = Blog.find(1)
        super
      end
    end

To turn on multiple actions:

    class PostController < APIController
      handles: :create, :show, :update, :destroy
    end

Or you can turn them all (including the [Specialized Actions](#specialized)):

    class PostController < APIController
      handles: :all
    end

For your reference, you can review the code of the equivalent actions in
[Controller Actions](actions.md)

<a id="specialized"></a>
####  Specialized Actions

<a id="error-handling"></a>
#### Error Handling

<a id="serializers"></a>
### Serializers

<a id="routes"></a>
### Routes

<a id="client"></a>
### Client

<a id="interaction"></a>
## Underlying Interaction

<a id="symantic-urls"></a>
### Symantic URLs

<a id="request-params"></a>
### Request Parameters

<a id="symantic-data"></a>
### Symantic Data

<a id="metadata"></a>
### Resposne Metadata

<a id="framework"></a>
## Framework Links

To better understand how a framework extends or alters the underlying Rails
technology.  Here are some additional details on how Daylight was built:

* [Framework Overview](framework.md)
* [Build Environment](environment.md)
* [Guiding Principles](principles.md)
