defmodule PhoenixPaper.SwitchTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Switch

  test "checked switch gets the checked-state classes via has-[:checked], not peer-checked" do
    html = render_component(&checked/1)

    assert html =~ "has-[:checked]:bg-pp-primary/50"
    assert html =~ "checked"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_switch name="wifi" checked={true} label="Wi-Fi" />
    """
  end

  test "paperize={false} renders a bare checkbox" do
    html = render_component(&bare/1)
    refute html =~ "has-[:checked]"
    assert html =~ "my-switch"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_switch paperize={false} name="wifi" class="my-switch" />
    """
  end
end
