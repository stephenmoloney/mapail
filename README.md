# Mapáil [![Build Status](https://travis-ci.org/stephenmoloney/mapail.svg)](https://travis-ci.org/stephenmoloney/mapail) [![Hex Version](http://img.shields.io/hexpm/v/mapail.svg?style=flat)](https://hex.pm/packages/mapail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/mapail)

Convert maps with string keys to an [elixir](http://elixir-lang.org/) struct.


## Features

- *String keyed maps*: Convert maps with string keys to a corresponding struct.

- *Transformations*: Optionally, string manipulations can be applied to the string of the map so as to attempt to
force the key to match the key of the struct. Currently, the only transformation option is conversion to snake_case.

- *Residual maps*: Optionally, the part of the map leftover after the struct has been built can be retrieved
or merged back into the returned struct.

## Example

```
defmodule User do
  defstruct [:first_name, :username, :password]
end
```

As seen below the map does not exactly match the struct keys due to
CamelCasing in this instance. `Mapáil` will attempt to match with the
struct keys by converting the unmatched keys to snake_case.
```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age": 30
        }

Mapail.map_to_struct(user, MapailTest.User)

{:ok, %User{
           first_name: "John",
           username: "john",
           password: "pass"
           }
}
```

If the same conversion is attempted with `transformations` turned off and
`rest` turned on, the keys would not match and the leftover map can optionally be
returned separately.

```elixir
Mapail.map_to_struct(user, MapailTest.User, transformations: [], rest: :true)

{:ok, %User{
           first_name: :nil,
           username: :nil,
           password: "pass"
           },
      %{
        "FirstName" => "John",
        "Username" => "john",
        "age" => 30
        }
}
```


## Documentation

- [Documentation](https://hexdocs.pm/mapail/api-reference.html) can be found in the hex package manager.

## Installation

The package can be installed as follows:

1. Add mapail to your list of dependencies in `mix.exs`:

      def deps do
        [{:mapail, "~> 0.2"}]
      end

2. Ensure mapail is started before your application:

      def application do
        [applications: [:mapail]]
      end

The package can be found in [hex](https://hexdocs.pm/mapail).

## Credit

This library has a dependency on the following libraries:
- [Maptu](https://hex.pm/packages/maptu) v1.0.0 library. For converting a matching map to a struct.
MIT © 2016 Andrea Leopardi, Aleksei Magusev. [Licence](https://github.com/lexhide/maptu/blob/master/LICENSE.txt)

## Licence

[MIT Licence](LICENSE.txt)