defmodule Memelex.TidBitTest do
  use ExUnit.Case


  test "construct a valid TidBit" do
    t = Memelex.TidBit.construct(%{title: "Test TidBit"})
    assert is_struct(t)
  end

  # test adding a tag which is a map

end
