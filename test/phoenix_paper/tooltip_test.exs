defmodule PhoenixPaper.TooltipTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Tooltip

  test "renders the title in a hidden-until-hover bubble" do
    html = render_component(&basic/1)

    assert html =~ "Delete"
    assert html =~ "opacity-0"
    assert html =~ "group-hover:opacity-100"
    assert html =~ "group-focus-within:opacity-100"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_tooltip title="Delete">
      <button>x</button>
    </.pp_tooltip>
    """
  end

  test "title=nil renders only the trigger, no tooltip bubble" do
    html = render_component(&no_title/1)

    refute html =~ "tooltip-bubble"
    assert html =~ "trigger"
  end

  defp no_title(assigns) do
    ~H"""
    <.pp_tooltip>
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "title=\"\" also disables the tooltip, matching MUI" do
    html = render_component(&empty_title/1)
    refute html =~ "tooltip-bubble"
  end

  defp empty_title(assigns) do
    ~H"""
    <.pp_tooltip title="">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "placement picks the position classes" do
    html = render_component(&right_placement/1)
    assert html =~ "left-full"
  end

  defp right_placement(assigns) do
    ~H"""
    <.pp_tooltip title="Info" placement="right">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "arrow renders an extra rotated square" do
    html = render_component(&with_arrow/1)
    assert html =~ "rotate-45"
  end

  defp with_arrow(assigns) do
    ~H"""
    <.pp_tooltip title="Info" arrow>
      <span>trigger</span>
    </.pp_tooltip>
    """
  end

  test "arrow={false} (default) renders no rotated square" do
    html = render_component(&basic/1)
    refute html =~ "rotate-45"
  end

  test "paperize={false}: no built-in classes on the bubble, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-on-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_tooltip title="Info" paperize={false} class="my-class">
      <span>trigger</span>
    </.pp_tooltip>
    """
  end
end
