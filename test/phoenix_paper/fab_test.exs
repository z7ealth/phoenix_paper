defmodule PhoenixPaper.FabTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Fab

  test "renders a circular button with elevation by default" do
    html = render_component(&circular/1)

    assert html =~ "rounded-full"
    assert html =~ "pp-elevation-6"
    assert html =~ "size-14"
    assert html =~ "cursor-pointer"
  end

  defp circular(assigns) do
    ~H"""
    <.pp_fab>+</.pp_fab>
    """
  end

  test "extended renders a labeled pill instead of a fixed square size" do
    html = render_component(&extended/1)

    assert html =~ "uppercase"
    assert html =~ "h-14"
    refute html =~ "size-14"
  end

  defp extended(assigns) do
    ~H"""
    <.pp_fab extended>Create</.pp_fab>
    """
  end

  test "ripple={false} drops the click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_fab ripple={false}>+</.pp_fab>
    """
  end
end
