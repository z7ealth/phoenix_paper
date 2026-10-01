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

  test "paperize={false} drops the click handler too, even with ripple defaulting true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end

  defp bare(assigns) do
    ~H"""
    <.pp_fab paperize={false}>+</.pp_fab>
    """
  end

  test "position emits a single position class, keeping the ripple's overflow-hidden" do
    html = render_component(&fixed_position/1)

    assert html =~ "fixed overflow-hidden"
    assert html =~ "bottom-6"
    refute html =~ "relative"
  end

  defp fixed_position(assigns) do
    ~H"""
    <.pp_fab position="fixed" class="bottom-6 right-6">+</.pp_fab>
    """
  end

  test "position without ripple still emits the position" do
    html = render_component(&absolute_no_ripple/1)

    assert html =~ "absolute"
    refute html =~ "overflow-hidden"
  end

  defp absolute_no_ripple(assigns) do
    ~H"""
    <.pp_fab position="absolute" ripple={false}>+</.pp_fab>
    """
  end
end
