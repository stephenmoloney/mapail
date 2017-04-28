# Changelog

## v1.0.2

[changes]
- Revert - Remove `mod: []` from applications. there is no application/supervisor
so this also causes release errors.

## v1.0.1

[changes]
- Add `:maptu` to apps in releases to remove warning when
making a release.
- Some changes to docs.

## v1.0.0

[breaking change]
- By default, no transformations will be applied. In versions, `v0.2.1` the
`:snake_case` transformation was applied by default. This is no longer the case.
If the `:snake_case` transformation is required, it needs to be passed explicitly
as an option. For example, `map_to_struct(map, module, transformations: [:snake_case])`
will apply transformations.
- Require versions of elixir >= 1.3

[changes]
- Update readme
- Update tests

[enhancements]
- added `stringify_map/1` function - will attempt to convert atom keys or
mixed atom/string keys in  a map to string keys only. The resultant map
can then be piped into `map_to_struct(map, module)`. This means that it
is now possible to convert atom-keyed, atom/string mixed keys maps and
string keyed maps into structs.

- added `struct_to_struct/3` function which allows for conversion of one
struct to another. This is anticipated to be used when there are two forms
of a struct very similar to each other and one needs to convert one
to the other.


## v0.2.1

[changes]
- Raise an error if mixed maps are passed. Only string-keyed maps from encoded sources are expected.


## v0.2.0

[changes]
- Remove dependency on `Morph.to_snake` in favour of `Macro.underscore`
- Remove dependency on logging utility `Og`
- Remove dependency on `stephenmoloney/maptu` and add module `Maptu.Extension`


## v0.1.0

- Initial release of master branch.