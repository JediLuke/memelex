defmodule Memex.My.PasswordsTest do
  use ExUnit.Case

  test "consecutive functionality of major functions" do

    assert Memex.My.Passwords.list == []

    Memex.My.Passwords.new %{label: "TestLabel", password: "testpass"}

    assert Memex.My.Passwords.list |> Enum.count() == 1
    assert hd(Memex.My.Passwords.list).label == "TestLabel"

    p = Memex.My.Passwords.find "TestLabel"
    assert p.password == "testpass"

    :ok = Memex.My.Passwords.update(p, %{password: "testpass_the_second"})
    p2 = Memex.My.Passwords.find "TestLabel"
    assert p2.password == "testpass_the_second"

    # shut down the memex & reboot it
    Application.stop(:memex)
    Application.ensure_all_started(:memex)

    :timer.sleep(:timer.seconds(1))

    p3 = Memex.My.Passwords.find "TestLabel"
    assert p3.password == "testpass_the_second" # it should have the most updated version, recovered from disc

  end

  #NEXT _ insert a password, and then delete it at the end, and then assert that the file is clean (just delete it? )

  # test cant set password to the redacted text (backup against programmer error)
end