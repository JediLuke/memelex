defmodule MemexTest do
  use ExUnit.Case


  test "one plus one equals two" do
    assert 1 + 1 == 2
  end

  test "one plus one does not equal three" do
    assert 1 + 1 != 3
  end
end
