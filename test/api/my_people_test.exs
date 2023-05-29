defmodule Memelex.My.PeopleTest do
  use ExUnit.Case

  test "add a new %Person{}" do
    Memelex.My.People.new(%{name: "John"})
  end

end
