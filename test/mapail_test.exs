defmodule MapailTest do
  use ExUnit.Case, async: :true
  doctest Mapail

  defmodule User do
    defstruct [:first_name, :username, :password]
  end

  defp expected(), do: %MapailTest.User{first_name: "John", username: "john", password: "pass"}

  test "Mapail.map_to_struct/2 - matching keys" do
    {:ok, actual} = Mapail.map_to_struct(%{"first_name" => "John", "username" => "john", "password" => "pass"}, MapailTest.User)
    assert(actual == expected())
  end

  test "Mapail.map_to_struct/2 - non-matching keys - `snake_case` transformations" do
    {:ok, actual} = Mapail.map_to_struct(%{"FirstName" => "John", "Username" => "john", "Password" => "pass"}, MapailTest.User)
    assert(actual == expected())
  end

  test "Mapail.map_to_struct/2 - non-matching keys - no transformations" do
    {:ok, actual} = Mapail.map_to_struct(%{"FirstName" => "John", "Username" => "john", "Password" => "pass"}, MapailTest.User, transformations: [])
    refute(actual == expected())
    assert(actual == %MapailTest.User{first_name: nil, username: nil, password: nil})
  end

  test "Mapail.map_to_struct/2 - non-matching keys - non-struct key-value pair discarded" do
    {:ok, actual} = Mapail.map_to_struct(%{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}, MapailTest.User)
    assert(actual == expected())
  end

  test "Mapail.map_to_struct/2 - non-matching keys - retain non-struct key-value pair in a separate map by setting `:rest` to `:true`" do
    {:ok, actual_struct, actual_rest} = Mapail.map_to_struct(%{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}, MapailTest.User, rest: :true)
    assert(actual_struct == expected())
    assert(actual_rest ==  %{"age" => 33})
  end

  test "Mapail.map_to_struct/2 - non-matching keys - retain non-struct key-value pair in a separate map - without transformations" do
    opts = [rest: :true, transformations: []]
    {:ok, actual_struct, actual_rest} = Mapail.map_to_struct(%{"FirstName" => "John", "Username" => "john", "password" => "pass", "age" => 33}, MapailTest.User, opts)
    refute(actual_struct ==  expected())
    refute(actual_rest ==  %{"age" => 33})
    assert(actual_struct ==  %MapailTest.User{first_name: :nil, username: :nil, password: "pass"})
    assert(actual_rest ==  %{"FirstName" => "John", "Username" => "john", "age" => 33})
  end

  test "Mapail.map_to_struct/2 - non-matching keys - retain non-struct key-value pair in the struct under the `:mapail` key by setting `rest` to :`merge`" do
    {:ok, actual_struct} = Mapail.map_to_struct(%{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}, MapailTest.User, rest: :merge)
    assert(actual_struct == Map.put(expected(), :mapail, %{"age" => 33}))
  end


end
