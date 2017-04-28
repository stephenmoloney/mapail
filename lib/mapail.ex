defmodule Mapail do
  @moduledoc ~S"""
  Helper library to convert a map into a struct or a struct to a struct.

  Convert string-keyed maps to structs by calling the
  `map_to_struct/3` function.

  Convert atom-keyed and atom/string mixed key maps to
  structs by piping the `stringify_map/1` into the `map_to_struct/3` function.

  Convert structs to structs by calling the `struct_to_struct/3` function.


  ## Note

  - The [Maptu](https://github.com/lexhide/maptu) library already provides many of the
   functions necessary for converting "encoded" maps to Elixir structs. Maptu may be
   all you need - see [Maptu](https://github.com/lexhide/maptu). Mapail builds on top
   of `Maptu` and incorporates it as a dependency.

  - `Mapail` offers a few additional more lenient approaches to the conversion process
  to a struct as explained in use cases. Maptu may be all you need though.


  ## Features

  - String keyed maps: Convert maps with string keys to a corresponding struct.

  - Transformations: Optionally, string manipulations can be applied to the key of the map so as to attempt to
  force the key to match the key of the struct. Currently, the only transformation option is conversion to snake_case.

  - Residual maps: Optionally, the part of the map leftover after the struct has been built can be retrieved
  or merged back into the returned struct.

  - Helper function for converting atom-keyed maps or string/atom mixed keyed maps to string-keyed only maps.

  - Helper function for converting a struct to another struct.


  ## Limitations

  - Currently, only converts one level deep, that is, it does not convert nested structs.
  This is a potential TODO task.


  ## Use Cases


  - Scenario 1:

  Map and Struct has a perfect match on the keys.

      map_to_struct(map, MODULE)` returns `{:ok, %MODULE{} = new_struct}


  - Scenario 2:

  Map and Struct has an imperfect match on the keys

      map_to_struct(map, MODULE, rest: :true)` returns `{:ok, %MODULE{} = new_struct, rest}


  - Scenario 3:

  Map and Struct has an imperfect match on the keys and a struct with and additional
  field named `:mapail` is returned. The value for the `:mapail` fields is a
  nested map with all non-matching key-pairs.


      map_to_struct(map, MODULE, rest: :merge)` returns `{:ok, %MODULE{} = new_struct}
      where `new_struct.mapail` contains the non-mathing `key-value` pairs.


  - Scenario 4:

  Map and Struct has an imperfect match on the keys. After an initial attempt to
  match the map keys to those of the struct keys, any non-matching keys are piped
  through transformation function(s) which modify the key of the map in an attempt
  to make a new match with the modified key. For now, the only transformations supported
  are `[:snake_case]`. `:snake_case` converts the non-matching keys to snake_case.

  ***NOTE***: This approach is lenient and will make matches that
  otherwise would not have matched. It might prove useful where a `json` encoded map
  returned from a server uses camelcasing and matches are otherwise missed. ***Only
  use this approach when it is explicitly desired behaviour***


      map_to_struct(map, MODULE, transformations: [:snake_case], rest: :true)
      returns `{:ok, new_struct, rest}`


  - Scenario 5:

  Map and Struct has a perfect match but the keys in the map are mixed case. Mapail
  provides a utility function which can help in this situation.

      stringify_map(map) |> map_to_struct(map, MODULE, rest: :false)
      returns {:ok, %MODULE{} = new_struct}


  - Scenario 6:

  Struct and Struct has a perfect match but the __struct__ fields are non-matching.

      struct_to_struct(%Notifications.Email{}, User.Email)` returns `{:ok, %User.Email{} = new_struct}


  ## Example - exact key matching (no transformations)


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


  ## Example - key matching with `transformations: [:snake_case]`


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


  ## Example - getting unmatched elements in a separate map


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


  ## Example - getting unmatched elements in a merged nested map


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


  ## Dependencies

  This library has a dependency on the following library:
  - [Maptu](https://hex.pm/packages/maptu) v1.0.0 library. For converting a matching map to a struct.
  MIT © 2016 Andrea Leopardi, Aleksei Magusev. [Licence](https://github.com/lexhide/maptu/blob/master/LICENSE.txt)
  """
  require Maptu.Extension
  @transformations [:snake_case]



  @doc """
  Convert a map with atom only or atom/string mixed keys
  to a map with string keys only.
  """
  @spec stringify_map(map) :: {:ok, map} | {:error, String.t}
  def stringify_map(map) do
    Enum.reduce(map, %{}, fn({k,v}, acc) ->
      try do
        Map.put(acc, Atom.to_string(k), v)
      rescue
        _e in ArgumentError ->
          is_binary(k) && Map.put(acc, k, v) || {:error, "the key is not an atom nor a binary"}
      end
    end)
  end



  @doc """
  Convert one form of struct into another struct.

  ## opts

  `[]` - same as `[rest: :false]`, `{:ok, struct}` is returned and any non-matching pairs
  will be discarded.

  `[rest: :true]`, `{:ok, struct, map}` is returned where map are the non-matching
  key-value pairs.

  `[rest: :false]`, `{:ok, struct}` is returned and any non-matching pairs
  will be discarded.
  """
  @spec struct_to_struct(map, atom, list) :: {:ok, struct} | {:ok, struct, map} | {:error, String.t}
  def struct_to_struct(old_struct, module, opts \\ []) do
    rest = Keyword.get(opts, :rest, :false)
    with {:ok, new_struct} <- Map.from_struct(old_struct)
         |> Mapail.stringify_map()
         |> Mapail.map_to_struct(module, rest: rest) do
      {:ok, new_struct}
    else
      {:ok, new_struct, rest} ->
        rest = Enum.reduce(rest, %{}, fn({k,v}, acc) ->
          {:ok, nk} = Maptu.Extension.to_existing_atom_safe(k)
          Map.put(acc, nk, v)
        end)
        {:ok, new_struct, rest}
      {:error, error} -> {:error, error}
    end
  end



  @doc """
  Convert one form of struct into another struct and raises an error on fail.
  """
  @spec struct_to_struct!(map, atom) :: struct | no_return
  def struct_to_struct!(old_struct, module) do
    case struct_to_struct(old_struct, module, rest: :false) do
      {:error, error} -> raise(ArgumentError, error)
      {:ok, new_struct} -> new_struct
    end
  end



  @doc ~s"""
  Converts a string-keyed map to a struct.

  ## Arguments

  - module: The module of the struct to be created.
  - map: The map to be converted to a struct.
  - opts: See below

    - `transformations: [atom]`:

    A list of transformations to apply to keys in the map where there are `non-matching`
    keys after the inital attempt to match.

    Defaults to `transformations: []` ie. no transformations are applied and only exactly matching keys are used to
    build a struct.

    If set to `transformations: [:snake_case]`, then after an initial run, non-matching keys are converted to
    snake_case form and another attempt is made to match the keys with the snake_case keys. This
    means less than exactly matching keys are considered a match when building the struct.


    - `rest: atom`:

    Defaults to `rest: :false`

    By setting `rest: :true`, the 'leftover' unmatched key-value pairs of the original map
    will also be returned in separate map with the keys in their original form.
    Returns as a tuple in the format `{:ok, struct, rest}`

    - By setting `rest: :merge`, the 'leftover' unmatched key-value pairs of the original map
    will be merged into the struct as a nested map under the key `:mapail`.
    Returns as a tuple in the format `{:ok, struct}`

    - By setting `rest: :false`, unmatched keys are silently discarded and only the struct
    is returned with matching keys. Returns as a tuple in the format `{:ok, struct}`.

  Example (matching keys):

      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5}, Range)
      {:ok, 1..5}

  Example (non-matching keys):

      iex> Mapail.map_to_struct(%{"line_or_bytes" => [], "Raw" => :false}, File.Stream)
      {:ok, %File.Stream{line_or_bytes: [], modes: [], path: nil, raw: true}}

  Example (non-matching keys - with `snake_case` transformations):

      iex> Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range, transformations: [:snake_case])
      {:ok, 1..5}

  Example (non-matching keys):

      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range); Map.keys(r);
      [:__struct__, :first, :last]

  Example (non-matching keys - with transformations):

      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "Last" => 5}, Range, transformations: [:snake_case]); Map.values(r);
      [Range, 1, 5]

  Example (non-matching keys):

      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range)
      {:ok, 1..5}

  Example (non-matching keys - capturing excess key-value pairs in separate map called rest):

      iex> Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :true)
      {:ok, 1..5, %{"next" => 3}}

  Example (non-matching keys - capturing excess key-value pairs and merging into struct under `:mapail` key):

      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge); Map.values(r);
      [Range, 1, 5, %{"next" => 3}]

      iex> {:ok, r} = Mapail.map_to_struct(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge); Map.keys(r);
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
  Converts a string-keyed map to a struct and raises if it fails.

   See `map_to_struct/3`

  Example (matching keys):

      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5}, Range)
      1..5

  Example (non-matching keys):

      iex> Mapail.map_to_struct!(%{"line_or_bytes" => [], "Raw" => :false}, File.Stream)
      %File.Stream{line_or_bytes: [], modes: [], path: nil, raw: true}

  Example (non-matching keys - with `snake_case` transformations):

      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range, transformations: [:snake_case])
      1..5

  Example (non-matching keys):

      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range) |> Map.keys();
      [:__struct__, :first, :last]

      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range) |> Map.values();
      [Range, 1, :nil]

  Example (non-matching keys - with transformations):

      iex> Mapail.map_to_struct!(%{"first" => 1, "Last" => 5}, Range, transformations: [:snake_case]) |> Map.values();
      [Range, 1, 5]

  Example (non-matching keys):

      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range)
      1..5

  Example (non-matching keys - capturing excess key-value pairs in separate map):

      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge) |> Map.values();
      [Range, 1, 5, %{"next" => 3}]

      iex> Mapail.map_to_struct!(%{"first" => 1, "last" => 5, "next" => 3}, Range, rest: :merge) |> Map.keys();
      [:__struct__, :first, :last, :mapail]

  """
  @spec map_to_struct!(map, atom, Keyword.t) :: struct | no_return
  def map_to_struct!(map, module, opts \\ []) do
    maptu_fn = if Keyword.get(opts, :rest, :false) == :merge, do: &Maptu.Extension.struct_rest/2, else: &Maptu.struct/2
    map_to_struct(map, module, maptu_fn, opts)
    |> Maptu.Extension.raise_on_error()
  end


  # private


  defp map_to_struct(map, module, maptu_fn, opts) do
    map_bin_keys = Map.keys(map)
    struct_bin_keys = module.__struct__() |> Map.keys() |> Enum.map(&Atom.to_string/1)
    non_matching_keys = non_matching_keys(map_bin_keys, struct_bin_keys)

    case non_matching_keys do
      [] ->
       try do
        maptu_fn.(module, map)
       rescue
        e in FunctionClauseError ->
         if e.function == :to_existing_atom_safe && e.module == Maptu && e.arity == 1 do
           {:error, :atom_key_not_expected}
         else
           {:error, :unexpected_error}
         end
       end
      _ ->
      {transformed_map, keys_trace} = apply_transformations(map, non_matching_keys, opts)
      unmatched_map = get_unmatched_map_with_original_keys(map, keys_trace)
      merged_map = Map.merge(transformed_map, unmatched_map)
      try do
        maptu_fn.(module, merged_map)
      rescue
        e in FunctionClauseError ->
          if e.function == :to_existing_atom_safe&& e.arity == 1 do
            {:error, :atom_key_not_expected}
          else
            {:error, :unexpected_error}
          end
      end
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
    transformations = Keyword.get(opts, :transformations, [])
    Enum.any?(transformations, &(Enum.member?(@transformations, &1) == :false)) &&
    (msg = "Unknown transformation in #{inspect(transformations)}, allowed transformations: #{inspect(@transformations)}"
    raise(ArgumentError, msg))
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
            key =
            case is_atom(k) do
              :true -> raise ArgumentError, "Mapail expects only maps with string keys."
              :false -> Macro.underscore(k) |> String.downcase()
            end
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
