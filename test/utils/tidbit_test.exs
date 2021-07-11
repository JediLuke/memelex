defmodule Memex.TidBitTest do
  use ExUnit.Case


  test "construct a valid TidBit" do
    t = Memex.TidBit.construct(%{title: "Test TidBit"})
    assert is_struct(t)
  end

end
