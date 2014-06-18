# API Testing

Daylight offers a simple mocking framework that simplifies the process of writing tests for your client code.

## Daylight::Mock

Works with both Rspec and TestUnit/Minitest.

To start add this to your +test_helper.rb+ or +spec_helper.rb+:

```ruby
Daylight::Mock.setup
```

The mock will simulate valid JSON responses to calls so you don't have to stub out anything, especially not the HTTP calls themselves.
At the end of the test you can examine the calls that were made by calling *daylight_mock*.

For example, say you want to test code that updates a User object.

```ruby
user = API::V1::User.find(1)
user.title = 'Grand Poobah'
user.save
```

This call to +daylight_mock+ returns a list of all the update calls made on a *User* object:
```ruby
daylight_mock.updated(:user)
```

To get only the last update use:
```ruby
daylight_mock.last_updated(:user)
```

Here's some things you can do with the recorded request:
```ruby
mock = daylight_mock.last_updated(:user)

mock.post_data
#==> {"user"=>{"id"=>1, "title"=>"Grand Poobah"}}

mock.status
#==> 201
```

Each recorded request keeps some data to check against:

| Attribute       | Description                                                                                     |
|-----------------|-------------------------------------------------------------------------------------------------|
| resource        | The resouce name                                                                                |
| path_parts      | A Struct of the request's path split into resource parts (version, resource, id and associated) |
| path            | The request's path                                                                              |
| response_body   | Daylight::Mock's response to the request                                                        |
| post_data       | The request's POST data                                                                         |
| params          | The request's parsed parameters                                                                 |
| action          | The request's action (:created, :updated, :associated...)                                       |
| status          | Response status                                                                                 |
| target_object   | The target object response if available (e.g. the response object to a find(1) call)            |
| request         | The raw request object                                                                          |
| response        | The raw response object                                                                         |

Supported Calls: *created, updated, associated, indexed, shown, deleted*


#### More Examples

```ruby
daylight_mock.updated(:post).count.must_equal 2

daylight_mock.last_updated(:post).target_object.node_type.must_equal 'wibble'

daylight_mock.last_created(:user).status.must_equal 201
```
