defmodule Maptu.Extension do
  @moduledoc """
  Contains custom functions extending [Maptu](https://github.com/lexhide/maptu)
  and superfluous to Maptu requirements. This module builds on top of `maptu.ex`
  and with extracts and modifications of `maptu.ex`. Mapail would not
  work without the additional functionality in this module.

  Maptu Creators:

      - [Andrea Leopardi](https://github.com/whatyouhide)
      - [Aleksei Magusev](https://github.com/lexmag)

  Maptu License:

      - MIT
      - https://github.com/lexhide/maptu/blob/master/LICENSE.txt

  Modified by:

      - Stephen Moloney
  """
  import Kernel, except: [struct: 1, struct: 2]

  @type non_strict_error_reason ::
    :missing_struct_key
    | :atom_key_not_expected
    | {:bad_module_name, binary}
    | {:non_existing_module, binary}
    | {:non_struct, module}

  @type strict_error_reason ::
    non_strict_error_reason
    | {:non_existing_atom, binary}
    | {:non_existing_module, binary}
    | {:unknown_struct_field, module, atom}

  # We use a macro for this so we keep a nice stacktrace.
  @doc :false
  defmacro raise_on_error(code) do
    quote do
      case unquote(code) do
        {:ok, result}    -> result
        {:ok, result, rest} -> rest
        {:error, reason} -> raise(ArgumentError, Maptu.Extension.format_error(reason))
      end
    end
  end

  @doc """
  Converts a map to a struct, silently capturing residual `key => value`
  pairs into a map with keys in the `String.t` format.

  `map` is a map with binary keys that represents a "dumped" struct; it must
  contain a `"__struct__"` key with a binary value that can be converted to a
  valid module name. If the value of `"__struct__"` is not a module name or it's
  a module that isn't a struct, then an error is returned.

  Keys in `map` that are not fields of the resulting struct are are collected along with their
  respective values into a separate map denoted by `rest`.

  This function returns `{:ok, struct, rest}` if the conversion is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.Extension.struct_rest(%{"__struct__" => "Elixir.URI", "port" => 8080, "foo" => 1})
      {:ok, %URI{port: 8080}, %{"foo" => 1}}

      iex> Maptu.Extension.struct_rest(%{"__struct__" => "Elixir.GenServer"})
      {:error, {:non_struct, GenServer}}

  """
  @spec struct_rest(map) :: {:ok, struct, map} | {:error, non_strict_error_reason}
  def struct_rest(map) do
    with {:ok, {mod_name, fields}} <- extract_mod_name_and_fields(map),
         :ok                       <- ensure_exists(mod_name),
         {:ok, mod}                <- module_to_atom(mod_name),
      do: struct_rest(mod, fields)
  end

  @doc """
  Behaves like `Maptu.Extension.struct_rest/1` but returns the residual `rest` map rather
  than the `struct` and raises in case of error.

  This function behaves like `Maptu.Extension.struct_rest/1`, but it returns the `rest` map (instead
  of `{:ok, struct, rest}`) if the conversion is valid, and raises an `ArgumentError`
  exception if it's not valid.

  ## Examples

      iex> Maptu.Extension.rest!(%{"__struct__" => "Elixir.URI", "port" => 8080})
      %{}

      iex> Maptu.Extension.rest!(%{"__struct__" => "Elixir.URI", "port" => 8080, "foo" => 1})
      %{"foo" => 1}

      iex> Maptu.Extension.rest!(%{"__struct__" => "Elixir.GenServer"})
      ** (ArgumentError) module is not a struct: GenServer

  """
  @spec rest!(map) :: map | no_return
  def rest!(map) do
    map |> struct_rest() |> raise_on_error()
  end

  @doc """
  Builds the `mod` struct with the given `fields`, silently capturing residual `key => value`
  pairs into a map with keys in the `String.t` format.

  This function takes a struct `mod` (`mod` should be a module that defines a
  struct) and a map of fields with binary keys. It builds the `mod` struct by
  safely parsing the fields in `fields`.

  If a key in `fields` doesn't map to a field in the resulting struct, the key and it's
  respective value are collected into a separate map denoted by `rest`.

  This function returns `{:ok, struct, rest}` if the building is successful,
  `{:error, reason}` otherwise.

  ## Examples

      iex> Maptu.Extension.struct_rest(URI, %{"port" => 8080, "nonexisting_field" => 1})
      {:ok, %URI{port: 8080}, %{"nonexisting_field" => 1}}
      iex> Maptu.Extension.struct_rest(GenServer, %{})
      {:error, {:non_struct, GenServer}}

  """
  @spec struct_rest(module, map) :: {:ok, struct, map} | {:error, non_strict_error_reason}
  def struct_rest(mod, fields) when is_atom(mod) and is_map(fields) do
    with :ok <- ensure_exists(mod),
         :ok <- ensure_struct(mod),
      do: fill_struct_rest(mod, fields)
  end


  @doc """
  Behaves like `Maptu.Extension.struct_rest/2` but returns the residual `rest` map rather than the `struct`
  and raises in case of error.

  This function behaves like `Maptu.Extension.struct_rest/2`, but it returns the `rest` map (instead
  of `{:ok, struct, rest}`) if the conversion is valid, and raises an `ArgumentError`
  exception if it's not valid.

  ## Examples

      iex> Maptu.Extension.rest!(URI, %{"port" => 8080, "nonexisting_field" => 1})
      %{"nonexisting_field" => 1}

      iex> Maptu.Extension.rest!(GenServer, %{})
      ** (ArgumentError) module is not a struct: GenServer

  """
  @spec rest!(module, map) :: map | no_return
  def rest!(mod, fields) do
    struct_rest(mod, fields) |> raise_on_error()
  end


  # Private or docless


  defp extract_mod_name_and_fields(%{"__struct__" => "Elixir." <> _} = map),
    do: {:ok, Map.pop(map, "__struct__")}
  defp extract_mod_name_and_fields(%{"__struct__" => name}),
    do: {:error, {:bad_module_name, name}}
  defp extract_mod_name_and_fields(%{}),
    do: {:error, :missing_struct_key}

  defp module_to_atom("Elixir." <> name = mod_name) do
    case to_existing_atom_safe(mod_name) do
      {:ok, mod} -> {:ok, mod}
      :error     -> {:error, {:non_existing_module, name}}
    end
  end

  defp ensure_exists(mod) when is_binary(mod) do
    try do
      String.to_existing_atom(mod)
    rescue
      ArgumentError ->
        error_mod = Module.split(mod) |> Enum.join(".")
        {:error, {:non_existing_module, error_mod}}
    else
      _atom -> :ok
    end
  end
  defp ensure_exists(mod) when is_atom(mod) do
    Atom.to_string(mod) |> ensure_exists()
  end

  defp ensure_struct(mod) when is_atom(mod) do
    if function_exported?(mod, :__struct__, 0) do
      :ok
    else
      {:error, {:non_struct, mod}}
    end
  end

  defp fill_struct_rest(mod, fields) do
    {result, rest} = Enum.reduce fields, {mod.__struct__(), %{}}, fn({bin_field, value}, {acc1, acc2}) ->
      case to_existing_atom_safe(bin_field) do
        {:ok, atom_field} ->
          if Map.has_key?(acc1, atom_field), do: {Map.put(acc1, atom_field, value), acc2}, else: {acc1, Map.put(acc2, bin_field, value)}
        :error ->
          {acc1, Map.put(acc2, bin_field, value)}
      end
    end
    {:ok, result, rest}
  end

#  @doc :false
#  This function can be extended if want to allow atom keys
#  def to_existing_atom_safe(arg) when is_atom(arg) do
#    {:ok, arg}
#  end
  @doc :false
  def to_existing_atom_safe(arg) when is_binary(arg) do
    try do
      String.to_existing_atom(arg)
    rescue
      ArgumentError -> :error
    else
      atom -> {:ok, atom}
    end
  end

  @doc :false
  def format_error(:missing_struct_key),
    do: "the given map doesn't contain a \"__struct__\" key"
  @doc :false
  def format_error(:atom_key_not_expected),
    do: "the map may contain an atom key which is not expected"
  @doc :false
  def format_error({:bad_module_name, name}) when is_binary(name),
    do: "not an elixir module: #{inspect name}"
  @doc :false
  def format_error({:non_existing_module, mod}) when is_binary(mod),
    do: "module doesn't exist: #{inspect mod}"
  @doc :false
  def format_error({:non_struct, mod}) when is_atom(mod),
    do: "module is not a struct: #{inspect mod}"
  @doc :false
  def format_error({:non_existing_atom, bin}) when is_binary(bin),
    do: "atom doesn't exist: #{inspect bin}"
  @doc :false
  def format_error({:unknown_struct_field, struct, field})
  when is_atom(struct) and is_atom(field),
    do: "unknown field #{inspect field} for struct #{inspect struct}"
end
