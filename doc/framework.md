# Daylight Framework

Daylight alters or extends Rails components.  Generally, there are 4 main parts to Daylight:

| Directory        | Function         |                                                             |
| ---------------- | ---------------- | ----------------------------------------------------------- |
| lib              | Client Modules   | Additions and fixes to `ActiveResource::Base`               |
| rails/daylight   | Server Modules   | Additions to the Rails MVC environment                      |
| rails/extensions | Rails Extensions | Patches/Fixes to Rails components and ActiveModelSerializer |
| app, config      | Documentation    | `Rails::Engine` to provide documentation of the API         |

## Client Modules

## Documentation

## Rails Extensions

| Extension                | Reason                                                        |
| ------------------------ | ------------------------------------------------------------- |
| autosave_association_fix | fix for autosaving `inverse_of` associations                  |
| has_one_serializer_ext   | modify serializer to recognize belong_to :through association |
| nested_attributes_ext    | allows association between two previously existing records    |
| read_only_attributes     | modfiy serializer to support `read_only` attributes           |
| render_json_meta         | mofify serializer to add metadata to the json response        |
| route_options            | extend routes to allow `associated` and `remoted` options     |
| versioned_url_for        | uses versioned paths for `url_for`                            |

## Documentation

