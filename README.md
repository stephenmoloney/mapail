# Mapáil [![Build Status](https://travis-ci.org/stephenmoloney/mapail.svg)](https://travis-ci.org/stephenmoloney/mapail) [![Hex Version](http://img.shields.io/hexpm/v/mapail.svg?style=flat)](https://hex.pm/packages/mapail) [![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)](https://hexdocs.pm/mapail)

Convert maps with string keys to an [elixir](http://elixir-lang.org/) struct.


## Features

- *String keyed maps*: Convert maps with string keys to a corresponding struct.

- *Transformations*: Optionally, string manipulations can be applied to the string of the map so as to attempt to
force the key to match the key of the struct. Currently, the only transformation option is conversion to snake_case.

- *Residual maps*: Optionally, the part of the map leftover after the struct has been built can be retrieved
or merged back into the returned struct.

## Examples


#### Example (1)

- Converting a map using the default settings which include coercions of keys
into the `snake_case` format and discarding any unmatching key-value pairs.

```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age" => 30
        }

defmodule User, do: defstruct [:first_name, :username, :password]

Mapail.map_to_struct(user, User)

{:ok, %User{
  first_name: "John",
  username: "john",
  password: "pass"
  }
}
```


#### Example (2)

- Converting a map without applying any transformations so that only exact matches
on key-value pairs will be used and unmatching key-value pairs will be discarded.

```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age" => 30
        }

defmodule User, do: defstruct [:first_name, :username, :password]

Mapail.map_to_struct(user, User, transformations: [])

{:ok, %User{
  first_name: nil,
  password: "pass",
  username: nil
  }
}
```

#### Example (3)

- Converting a map without applying any transformations so that only exact matches
on key-value pairs will be used and unmatching key-value pairs will be returned as a separate map.

```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age" => 30
        }

defmodule User, do: defstruct [:first_name, :username, :password]

Mapail.map_to_struct(user, User, transformations: [], rest: :true)

{:ok, %User{
  first_name: nil,
  password: "pass",
  username: nil
  },
  %{
  "FirstName" => "John",
  "Username" => "john",
  "age" => 30
  }
}
```

#### Example (4)

- Converting a map using the default settings which include coercions of keys
into the `snake_case` format and unmatching key-value pairs will be merged back into
the original map under the `:mapail` key.

```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age" => 30
        }

defmodule User, do: defstruct [:first_name, :username, :password]

Mapail.map_to_struct(user, User, rest: :merge)

{:ok, %{
    __struct__: User,
    first_name: "John",
    password: "pass",
    username: "john",
    mapail: %{
      "FirstName" => "John",
      "Username" => "john",
      "age" => 30
    }
  }
}

```

#### Example (5)

- Converting a map without applying any transformations so that only exact matches
on key-value pairs will be used and unmatching key-value pairs will be merged back into
the original map under the `:mapail` key.

```elixir
user = %{
        "FirstName" => "John",
        "Username" => "john",
        "password" => "pass",
        "age" => 30
        }

defmodule User, do: defstruct [:first_name, :username, :password]

Mapail.map_to_struct(user, User, transformations: [], rest: :merge)

{:ok, %{
    __struct__: User,
    first_name: nil,
    password: "pass",
    username: nil,
    mapail: %{
      "FirstName" => "John",
      "Username" => "john",
      "age" => 30
    },
  }
}
```



## Documentation

- [Documentation](https://hexdocs.pm/mapail/api-reference.html) can be found in the hex package manager.

## Installation

The package can be installed as follows:

1. Add mapail to your list of dependencies in `mix.exs`:

```
def deps do
  [{:mapail, "~> 0.2"}]
end
```

2. Ensure mapail is started before your application:

```
def application do
  [applications: [:mapail]]
end
```

The package can be found in [hex](https://hexdocs.pm/mapail).

## Credit

This library has a dependency on the following libraries:
- [Maptu](https://hex.pm/packages/maptu) v1.0.0 library. For converting a matching map to a struct.
MIT © 2016 Andrea Leopardi, Aleksei Magusev. [Licence](https://github.com/lexhide/maptu/blob/master/LICENSE.txt)

## Licence

[MIT Licence](LICENSE.txt)