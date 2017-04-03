# Mapáil [![Build Status](https://travis-ci.org/stephenmoloney/mapail.svg)](https://travis-ci.org/stephenmoloney/mapail) [![Hex Version](http://img.shields.io/hexpm/v/mapail.svg?style=flat)](https://hex.pm/packages/mapail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/mapail)

Helper library to convert a map into a struct or a struct to a struct.


## Features


- String keyed maps: Convert maps with string keys to a corresponding struct.

- Transformations: Optionally, string manipulations can be applied to the key of the map so as to attempt to
force the key to match the key of the struct. Currently, the only transformation option is conversion to snake_case.

- Residual maps: Optionally, the part of the map leftover after the struct has been built can be retrieved
or merged back into the returned struct.

- Helper function for converting atom-keyed maps or string/atom mixed keyed maps to string-keyed only maps.

- Helper function for converting a struct to another struct.


## Examples


#### Example - exact key matching (no transformations)

```elixir
defmodule User do
  defstruct [:first_name, :username, :password]
end

user = %{
  "FirstName" => "John",
  "Username" => "john",
  "password" => "pass",
  "age" => 30
}

Mapail.map_to_struct(user, User)

{:ok, %User{
  first_name: :nil,
  username: :nil,
  password: "pass"
  }
}
```


#### Example - key matching with `transformations: [:snake_case]`

```elixir
defmodule User do
  defstruct [:first_name, :username, :password]
end

user = %{
  "FirstName" => "John",
  "Username" => "john",
  "password" => "pass",
  "age" => 30
}

Mapail.map_to_struct(user, User, transformations: [:snake_case])

{:ok, %User{
  first_name: "John",
  username: "john",
  password: "pass"
  }
}
```

#### Example - getting unmatched elements in a separate map

```elixir
defmodule User do
  defstruct [:first_name, :username, :password]
end

user = %{
  "FirstName" => "John",
  "Username" => "john",
  "password" => "pass",
  "age" => 30
}

{:ok, user_struct, leftover} = Mapail.map_to_struct(user, User, rest: :true)


{:ok, %User{
  first_name: :nil,
  username: "pass",
  password: :nil
  },
  %{
    "FirstName" => "John",
    "Username" => "john",
    "age" => 30
  }
}
```

#### Example - getting unmatched elements in a merged nested map

```elixir
defmodule User do
  defstruct [:first_name, :username, :password]
end

user = %{
  "FirstName" => "John",
  "Username" => "john",
  "password" => "pass",
  "age" => 30
}

Mapail.map_to_struct(user, User, rest: :merge)

{:ok, %User{
  first_name: :nil,
  username: "pass",
  password: :nil,
  mapail: %{
    "FirstName" => "John",
    "Username" => "john",
    "age" => 30
  }
}
```


## Documentation

- [Documentation](https://hex.pm/packages/mapail) can be found in the hex package manager.


## Installation

The package can be installed as follows:

1. Add mapail to your list of dependencies in `mix.exs`:

```
def deps do
  [{:mapail, "~> 1.0"}]
end
```

2. Ensure mapail is started before your application:

```
def application do
  [applications: [:mapail]]
end
```

The package can be found in [hex](https://hex.pm/packages/mapail).


## Credit

This library depends on the following library:
- [Maptu](https://hex.pm/packages/maptu) v1.0.0 library. For converting a matching map to a struct.
MIT © 2016 Andrea Leopardi, Aleksei Magusev. [Licence](https://github.com/lexhide/maptu/blob/master/LICENSE.txt)


## Licence

[MIT Licence](LICENSE.txt)