defmodule PhoenixPaper.ToggleButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.ToggleButton

  test "pressed renders the filled state and aria-pressed=true" do
    html = render_component(&pressed/1)

    assert html =~ "bg-pp-primary"
    assert html =~ ~s(aria-pressed="true")
  end

  defp pressed(assigns) do
    ~H"""
    <.pp_toggle_button pressed={true}>Bold</.pp_toggle_button>
    """
  end

  test "unpressed renders the outline state and aria-pressed=false" do
    html = render_component(&unpressed/1)

    refute html =~ "border-pp-primary bg-pp-primary"
    assert html =~ "border-pp-outline"
    assert html =~ ~s(aria-pressed="false")
  end

  defp unpressed(assigns) do
    ~H"""
    <.pp_toggle_button>Bold</.pp_toggle_button>
    """
  end

  test "ripple={false} drops the click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_toggle_button ripple={false}>Bold</.pp_toggle_button>
    """
  end

  test "paperize={false} drops the click handler too, even with ripple defaulting true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end

  defp bare(assigns) do
    ~H"""
    <.pp_toggle_button paperize={false}>Bold</.pp_toggle_button>
    """
  end

  test "shows a pointer cursor on hover" do
    html = render_component(&unpressed/1)
    assert html =~ "cursor-pointer"
  end
end
