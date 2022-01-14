defmodule Memelex.My.PasswordsTest do
  use ExUnit.Case

  test "consecutive functionality of major functions" do

    assert Memelex.My.Passwords.list == []

    Memelex.My.Passwords.new %{label: "TestLabel", password: "testpass"}

    assert Memelex.My.Passwords.list |> Enum.count() == 1
    assert hd(Memelex.My.Passwords.list).label == "TestLabel"

    p = Memelex.My.Passwords.find "TestLabel"
    assert p.password == "testpass"

    :ok = Memelex.My.Passwords.update(p, %{password: "testpass_the_second"})
    p2 = Memelex.My.Passwords.find "TestLabel"
    assert p2.password == "testpass_the_second"

    # shut down the memex & reboot it
    Application.stop(:memelex)
    Application.ensure_all_started(:memelex)

    :timer.sleep(:timer.seconds(1))

    p3 = Memelex.My.Passwords.find "TestLabel"
    assert p3.password == "testpass_the_second" # it should have the most updated version, recovered from disc

  end

  #NEXT _ insert a password, and then delete it at the end, and then assert that the file is clean (just delete it? )

  # test cant set password to the redacted text (backup against programmer error)
end