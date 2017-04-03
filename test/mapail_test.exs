defmodule MapailTest do
  use ExUnit.Case, async: :true
  alias Mapail.User
  alias Mapail.AlternateUser
  doctest Mapail


  test "stringify_map/1 - string keys" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass"}
    actual_params = Mapail.stringify_map(params)
    assert(actual_params == params)
  end

  test "stringify_map/1 - atom keys" do
    params = %{first_name: "John", username: "john", password: "pass"}
    actual_params = Mapail.stringify_map(params)
    expected_params = %{"first_name" => "John", "username" => "john", "password" => "pass"}
    assert(actual_params == expected_params)
  end

  test "stringify_map/1 - mixed atom/string keys" do
    params = %{"username" => "john", first_name: "John", password: "pass"}
    actual_params = Mapail.stringify_map(params)
    expected_params = %{"first_name" => "John", "username" => "john", "password" => "pass"}
    assert(actual_params == expected_params)
  end

  test "stringify_map/1 - contains non string or atom keys" do
    params = %{%File.Stream{} => "john", first_name: "John", password: "pass"}
    actual_params = Mapail.stringify_map(params)
    assert(actual_params == {:error, "the key is not an atom nor a binary"})
  end

  test "struct_to_struct/3 - (1)" do
    user = %User{first_name: "John", username: "john", password:  "pass"}
    {:ok, actual_user} = Mapail.struct_to_struct(user, AlternateUser)
    expected_user = %AlternateUser{first_name: "John", username: "john", password:  "pass", email: :nil}
    assert(actual_user == expected_user)
  end

  test "struct_to_struct/3 - (2)" do
    user = %AlternateUser{first_name: "John", username: "john", password:  "pass", email: "email_address"}
    {:ok, actual_user} = Mapail.struct_to_struct(user, User)
    expected_user = %User{first_name: "John", username: "john", password:  "pass"}
    assert(actual_user == expected_user)
  end

  test "struct_to_struct/3 - (3)" do
    user = %AlternateUser{first_name: "John", username: "john", password:  "pass", email: "email_address"}
    {:ok, actual_user, actual_rest} = Mapail.struct_to_struct(user, User, rest: :true)
    expected_user = %User{first_name: "John", username: "john", password:  "pass"}
    expected_rest = %{email: "email_address"}
    assert(actual_user == expected_user)
    assert(actual_rest == expected_rest)
  end

  test "struct_to_struct!/2 - (1)" do
    user = %User{first_name: "John", username: "john", password:  "pass"}
    actual_user = Mapail.struct_to_struct!(user, AlternateUser)
    expected_user = %AlternateUser{first_name: "John", username: "john", password:  "pass", email: :nil}
    assert(actual_user == expected_user)
  end

  test "struct_to_struct!/2 - (2)" do
    user = %AlternateUser{first_name: "John", username: "john", password:  "pass", email: "email_address"}
    actual_user = Mapail.struct_to_struct!(user, User)
    expected_user = %User{first_name: "John", username: "john", password:  "pass"}
    assert(actual_user == expected_user)
  end

  test "Mapail.map_to_struct/3 - perfect match" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass"}
    {:ok, actual} = Mapail.map_to_struct(params, User)
    expected = %User{first_name: "John", username: "john", password: "pass"}
    assert(actual == expected)
  end

  test "Mapail.map_to_struct/3 - non-matching keys - opts default transformations: []" do
    params = %{"FirstName" => "John", "Username" => "john", "Password" => "pass"}
    {:ok, actual} = Mapail.map_to_struct(params, User, transformations: [])
    expected = %User{first_name: :nil, username: :nil, password: :nil}
    assert(actual == expected)
  end

  test "Mapail.map_to_struct/3 - non-matching keys - opts transformations: [:snake_case]" do
    params = %{"FirstName" => "John", "Username" => "john", "Password" => "pass"}
    {:ok, actual} = Mapail.map_to_struct(params, User, transformations: [:snake_case])
    expected = %User{first_name: "John", username: "john", password: "pass"}
    assert(actual == expected)
  end

  test "Mapail.map_to_struct/3 - non-matching keys - opts default, [rest: :false]" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}
    {:ok, actual} = Mapail.map_to_struct(params, User)
    expected = %User{first_name: "John", username: "john", password: "pass"}
    assert(actual == expected)
  end

  test "Mapail.map_to_struct/3 - non-matching keys - opts [rest: :true]" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}
    {:ok, actual_struct, actual_rest} = Mapail.map_to_struct(params, User, rest: :true)
    expected = %User{first_name: "John", username: "john", password: "pass"}
    assert(actual_struct == expected)
    assert(actual_rest ==  %{"age" => 33})
  end

  test "Mapail.map_to_struct/3 - non-matching keys - opts = `[rest: :true, transformations: []]`" do
    opts = [rest: :true, transformations: []]
    params = %{"FirstName" => "John", "Username" => "john", "password" => "pass", "age" => 33}
    {:ok, actual_struct, actual_rest} = Mapail.map_to_struct(params, User, opts)
    expected_struct = %User{first_name: :nil, username: :nil, password: "pass"}
    expected_rest = %{"FirstName" => "John", "Username" => "john", "age" => 33}
    assert(actual_struct == expected_struct)
    assert(actual_rest == expected_rest)
  end
  test "Mapail.map_to_struct/3 - non-matching keys - opts `[rest: :merge]`" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", "age" => 33}
    {:ok, actual_struct} = Mapail.map_to_struct(params, User, rest: :merge)
    expected = %User{first_name: "John", username: "john", password: "pass"} |> Map.put(:mapail, %{"age" => 33})
    assert(actual_struct == expected)
  end

  test "Mapail.map_to_struct/3 - non-matching keys - mixed maps - error handling" do
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
    {:error, actual_error} = Mapail.map_to_struct(params, User, rest: :merge)
    expected_error = :atom_key_not_expected
    assert(actual_error == expected_error)
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
    {:error, actual_error} = Mapail.map_to_struct(params, User, rest: :true)
    expected_error = :atom_key_not_expected
    assert(actual_error == expected_error)
    params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
    {:error, actual_error} = Mapail.map_to_struct(params, User)
    expected_error = :atom_key_not_expected
    assert(actual_error == expected_error)
  end

  test "Mapail.map_to_struct!/3 - non-matching keys - mixed maps - exception handling" do
    assert_raise(ArgumentError, fn() ->
      params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
      Mapail.map_to_struct!(params, User, rest: :merge)
    end)
    assert_raise(ArgumentError, fn() ->
      params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
      Mapail.map_to_struct!(params, User, rest: :true)
    end)
    assert_raise(ArgumentError, fn() ->
      params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
      Mapail.map_to_struct!(params, User, rest: :false)
    end)
    try do
      params = %{"first_name" => "John", "username" => "john", "password" => "pass", :age => 33}
      Mapail.map_to_struct!(params, User)
    rescue
      e in ArgumentError ->
       expected_msg = "the map may contain an atom key which is not expected"
       actual_msg = e.message
       assert(actual_msg == expected_msg)
    end
  end


end
