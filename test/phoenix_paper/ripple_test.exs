defmodule PhoenixPaper.RippleTest do
  use ExUnit.Case, async: true

  alias PhoenixPaper.Ripple

  test "on_click/1 returns nil when disabled, so HEEx drops the attribute" do
    assert Ripple.on_click(false) == nil
  end

  test "on_click/1 returns the ripple script when enabled" do
    script = Ripple.on_click(true)

    assert is_binary(script)
    assert script =~ "createElement('span')"
    assert script =~ "getBoundingClientRect"
  end

  test "container_classes/1 adds relative overflow-hidden only when enabled" do
    assert Ripple.container_classes(true) == "relative overflow-hidden"
    assert Ripple.container_classes(false) == ""
  end
end
