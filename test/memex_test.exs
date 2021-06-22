defmodule MemexTest do
  use ExUnit.Case
  doctest Memex

  test "greets the world" do
    assert Memex.hello() == :world
  end
end
