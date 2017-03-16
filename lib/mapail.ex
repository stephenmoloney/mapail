defmodule Mapail do
  @moduledoc ~S"""
  Helper library to convert a `map` with string keys into structs.


  ## Rationale

  It can be laborious to reconstruct the key-value pairs of a map manually into a struct on a case by case basis.
  This particularly can be the case when maps originate from `json` and the formatting of the json is not
  immediately amenable to conversion to a struct. Often, the user may have to perform string transformations
  on the `json` in order to convert it to an atom. Doing a simple `Enum.map(String.to_atom/1)` runs the risk of
  exceeding the maximum number of atoms in the erlang VM. This library tries to assist in the coercion of json
  to a map by providing a `map_to_struct/2` function.


  ## Features

  - *Transformations*: Optionally, string manipulations can be applied to the string of the map so as to attempt to
  force the key to match the key of the struct. Currently, the only transformation option is conversion to snake_case.

  - *Residual maps*: Optionally, the part of the map leftover after the struct has been built can be retrieved
  or merged back into the returned struct.


  ## Limitations

  - Currently, only converts one level deep, that is, it does not convert nested structs. This is a potential TODO task.

  ## Example

      defmodule User do
        defstruct [:first_name, :username, :password]
      end

  As seen below the map does not exactly match the struct keys due to
  CamelCasing in this instance. `Mapáil` will attempt to match with the
  struct keys by converting the unmatched keys to snake_case.

      user = %{
              "FirstName" => "John",
              "Username" => "john",
              "password" => "pass",
              "age": 30
              }

      Mapail.map_to_struct(user, User)

      {:ok, %User{
                 first_name: "John",
                 username: "john",
                 password: "pass"
                 }
      }

  If the same conversion is attempted with `transformations` turned off and
  `rest` turned on, the keys would not match and the leftover map can optionally be
  returned separately.

  Mapail.map_to_struct(user, User, transformations: [], rest: :true)

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


  ## Dependencies

  This library has a dependency on the following libraries:
  - [Maptu](https://hex.pm/packages/maptu) v0.1.0 library. For converting a matching map to a struct.
  MIT © 2016 Andrea Leopardi, Aleksei Magusev. [Licence]()
  - [Morph](https://hex.pm/packages/morph) v0.1.0 library. For converting strings to snake_case strings.
  Copyright (c) 2016, Charles Moncrief [Licence](https://github.com/cmoncrief/elixir-morph/blob/master/LICENSE)

  """
  require Maptu


  @doc ~s"""
  Converts a map to a struct.

  ## Arguments

  - `module`: The module of the struct to be created.
  - `map`: The map to be converted to a struct.
  - `opts`: See opts section.

  ## opts

  - `transformations`: A list of transformations to apply to keys in the map in an attempt to make
  more matches with the keys in the struct. Defaults to `[:snake_case]`. *Warning: In the event of a match
  to a transformed key such as a key transformed to snake_case, the original map key is modified to `snake_case`
  and it's value is added to the struct.* If set to `[]`, then no transformations are applied and only strings
  matching exactly to the struct atoms are matched. The transformations are only applied to keys of the map that
  do not initially match any key in the struct.

  - `rest`: `:false`, `:true` or `:merge`
      - By setting `rest` to `:true`, the 'leftover' unmatched key-value pairs of the original map
      will also be returned in separate map with the keys in their original form.
      Returns as a tuple in the format `{:ok, struct, rest}`
      - By setting `rest` to `:merge`, the 'leftover' unmatched key-value pairs of the original map
      will be merged into the struct under the key `:mapail`.
      Returns as a tuple in the format `{:ok, struct}`
      - By setting `rest` to `:false`, unmatched keys are silently discarded and only the struct
      is returned with matching keys. Defaults to `:false`
      Returns as a tuple in the format `{:ok, struct}`

  Example (matching keys):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5}
      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5}, Range)
      {:ok, 1..5}

  Example (non-matching keys - with `snake_case` transformations):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "Last" => 5}
      iex> Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range)
      {:ok, 1..5}

  Example (non-matching keys - without transformations):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "Last" => 5}
      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range, transformations: []); Map.keys(r);
      [:__struct__, :first, :last]
      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range, transformations: []); Map.values(r);
      [Range, 1, nil]

  Example (non-matching keys):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5, "next" => 3}
      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range)
      {:ok, 1..5}

  Example (non-matching keys - capturing excess key-value pairs in separate map):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5, "next" => 3}
      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :true)
      {:ok, 1..5, %{"next" => 3}}

  Example (non-matching keys - capturing excess key-value pairs and merging into struct under `:mapail` key):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5, "next" => 3}
      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge); Map.values(r);
      [Range, 1, 5, %{"next" => 3}]
      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge); Map.keys(r)
      [:__struct__, :first, :last, :mapail]

  """
  @spec map_to_struct(map, atom, Keyword.t) :: {:error, Maptu.Extension.non_strict_error_reason} |
                                               {:ok, struct} |
                                               {:ok, struct, map}
  def map_to_struct(map, module, opts \\ []) do
    maptu_fn = if Keyword.get(opts, :rest, :false) in [:true, :merge], do: &Maptu.Extension.struct_rest/2, else: &Maptu.struct/2
    map_to_struct(map, module, maptu_fn, opts)
  end


  @doc ~s"""
  Converts a map to a struct.

  ## Arguments

  - `module`: The module of the struct to be created.
  - `map`: The map to be converted to a struct.
  - `opts`: See opts section.

  ## opts

  - `transformations`: A list of transformations to apply to keys in the map in an attempt to make
  more matches with the keys in the struct. Defaults to `[:snake_case]`. *Warning: In the event of a match
  to a transformed key such as a key transformed to snake_case, the original map key is modified to `snake_case`
  and it's value is added to the struct.* If set to `[]`, then no transformations are applied and only strings
  matching exactly to the struct atoms are matched. The transformations are only applied to keys of the map that
  do not initially match any key in the struct.

  - `rest`: `:false` or `:merge`
      - By setting `rest` to `:merge`, the 'leftover' unmatched key-value pairs of the original map
      will be merged into the struct under the key `:mapail`.
      - By setting `rest` to `:false`, unmatched keys are silently discarded and only the struct
      is returned with matching keys. Defaults to `:false`

  Example (matching keys):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5}
      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5}, Range)
      1..5

  Example (non-matching keys - with `snake_case` transformations):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "Last" => 5}
      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range)
      1..5

  Example (non-matching keys - without transformations):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "Last" => 5}
      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range, transformations: []) |> Map.values
      [Range, 1, nil]
      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range, transformations: []) |> Map.keys
      [:__struct__, :first, :last]

  Example (non-matching keys):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5, "next" => 3}
      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range)
      1..5

  Example (non-matching keys - capturing excess key-value pairs in separate map):
      %Range{first: 1, last: 5} <==> %{"first" => 1, "last" => 5, "next" => 3}
      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge) |> Map.values
      [Range, 1, 5, %{"next" => 3}]
      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge) |> Map.keys
      [:__struct__, :first, :last, :mapail]

  """
  @spec map_to_struct!(map, atom, Keyword.t) :: struct | no_return
  def map_to_struct!(map, module, opts \\ []) do
    maptu_fn = if Keyword.get(opts, :rest, :false) == :merge, do: &Maptu.Extension.struct_rest/2, else: &Maptu.struct/2
    case map_to_struct(map, module, maptu_fn, opts) do
      {:error, error} -> raise(ArgumentError, error)
      {:ok, result} -> result
    end
  end


  defp map_to_struct(map, module, maptu_fn, opts) do
    map_bin_keys = Map.keys(map)
    struct_bin_keys = module.__struct__() |> Map.keys() |> Enum.map(&Atom.to_string/1)
    non_matching_keys = non_matching_keys(map_bin_keys, struct_bin_keys)

    case non_matching_keys do
      [] -> maptu_fn.(module, map)
      _ ->
      {transformed_map, keys_trace} = apply_transformations(map, non_matching_keys, opts)
#      transformed_map_keys = Map.keys(transformed_map)
      unmatched_map = get_unmatched_map_with_original_keys(map, keys_trace)
      merged_map = Map.merge(transformed_map, unmatched_map)
      maptu_fn.(module, merged_map)
      |> remove_transformed_unmatched_keys(keys_trace)
    end
    |> case do
        {:ok, res, rest} ->
          if opts[:rest] == :merge do
            {:ok, Map.put(res, :mapail, rest)}
          else
            {:ok, res, rest}
          end
        {:ok, res} -> {:ok, res}
        {:error, reason} -> {:error, reason}
      end

  end


  defp non_matching_keys(map_bin_keys, struct_bin_keys) do
    matching = Enum.filter(struct_bin_keys,
      fn(struct_key) -> Enum.member?(map_bin_keys, struct_key) end
    )
    non_matching = Enum.reject(map_bin_keys,
      fn(map_key) -> Enum.member?(matching, map_key) end
    )
    non_matching
  end


  defp get_unmatched_map_with_original_keys(map, keys_trace) do
    Enum.reduce(keys_trace, %{},
      fn({k, v}, acc) ->
        if k !== v do
          Map.put(acc, k, Map.fetch!(map, k))
        else
          acc
        end
      end
      )
  end


  defp apply_transformations(map, non_matching_keys, opts) do
    transformations = Keyword.get(opts, :transformations, [:snake_case])
    {transformed_map, keys_trace} =
    if :snake_case in transformations do
      to_snake_case(map, non_matching_keys)
    else
      keys_trace = Enum.reduce(map, %{}, fn({k, _v}, acc) -> Map.put(acc, k, k) end)
      {map, keys_trace}
    end
    {transformed_map, keys_trace}
  end


  defp to_snake_case(map, non_matching_keys) do
    Enum.reduce(map, {map, %{}},
      fn({k, v}, {mod_map, keys_trace}) ->
        case k in non_matching_keys do
          :true ->
            key = Macro.underscore(k) |> String.downcase()
            {
            Map.delete(mod_map, k) |> Map.put(key, v),
            Map.put(keys_trace, k, key),
            }
          :false ->
            {
            mod_map,
            Map.put(keys_trace, k, k)
            }
        end
      end
    )
  end


  defp remove_transformed_unmatched_keys({:error, reason}, _keys_trace) do
    {:error, reason}
  end
  defp remove_transformed_unmatched_keys({:ok, res}, _keys_trace) do
    {:ok, res}
  end
  defp remove_transformed_unmatched_keys({:ok, res, rest}, keys_trace) do
    rest =
    Enum.reduce(keys_trace, rest,
        fn({orig_k, trans_k}, acc) ->
          if orig_k !== trans_k && Map.has_key?(acc, trans_k) do
            Map.delete(acc, trans_k)
          else
            acc
          end
        end
      )
    {:ok, res, rest}
  end


end
