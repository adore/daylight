# Daylight Framework

Daylight alters or extends Rails components.  Generally, there are 4 main parts
to Daylight:

| Directory        | Function         |                                                             |
| ---------------- | ---------------- | ----------------------------------------------------------- |
| lib              | Client Modules   | Additions and fixes to `ActiveResource::Base`               |
| rails/daylight   | Server Modules   | Additions to the Rails MVC environment                      |
| rails/extensions | Rails Extensions | Patches/Fixes to Rails components and ActiveModelSerializer |
| app, config      | Documentation    | `Rails::Engine` to provide documentation of the API         |

## Client Modules

## Documentation

## Rails Extensions

Here is the list of extensions and the reason why they are required.  Each
extension is loaded in `rails/server.rb`

| Extension                | Reason                                                                       |
| ------------------------ | ---------------------------------------------------------------------------- |
| autosave_association_fix | fix `ActiveRecord::Base` autosaving `inverse_of` associations                |
| has_one_serializer_ext   | modify `ActiveModel::Serializer` to recognize belong_to :through association |
| read_only_attributes     | modfiy `ActiveModel::Serializer` to support `read_only` attributes           |
| render_json_meta         | mofify `ActiveModel::Serializer` to include metadata to the json response    |
| nested_attributes_ext    | allows `ActiveRecord::Base` association between previously existing records  |
| route_options            | extend routes to allow `associated` and `remoted` options                    |
| versioned_url_for        | uses any versioned paths for `url_for`                                       |

## Documentation

