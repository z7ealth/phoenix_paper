defmodule PhoenixPaper.ButtonGroupTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Button
  import PhoenixPaper.ButtonGroup

  test "rounds only the group's outer corners and collapses inner borders" do
    html = render_component(&group/1)

    assert html =~ "first-child]:rounded-l-md"
    assert html =~ "last-child]:rounded-r-md"
    assert html =~ "not(:first-child)]:-ml-px"
  end

  defp group(assigns) do
    ~H"""
    <.pp_button_group>
      <.pp_button variant="outlined">Left</.pp_button>
      <.pp_button variant="outlined">Right</.pp_button>
    </.pp_button_group>
    """
  end

  test "orientation=\"vertical\" rounds top/bottom instead of left/right and collapses top borders" do
    html = render_component(&vertical/1)

    assert html =~ "first-child]:rounded-t-md"
    assert html =~ "last-child]:rounded-b-md"
    assert html =~ "not(:first-child)]:-mt-px"
    refute html =~ "rounded-l-md"
    refute html =~ "rounded-r-md"
  end

  defp vertical(assigns) do
    ~H"""
    <.pp_button_group orientation="vertical">
      <.pp_button variant="outlined">Top</.pp_button>
      <.pp_button variant="outlined">Bottom</.pp_button>
    </.pp_button_group>
    """
  end

  test "disable_elevation forces every child's elevation shadow to 0" do
    html = render_component(&disable_elevation/1)

    assert html =~ "*]:pp-elevation-0"
  end

  defp disable_elevation(assigns) do
    ~H"""
    <.pp_button_group disable_elevation>
      <.pp_button>Left</.pp_button>
      <.pp_button>Right</.pp_button>
    </.pp_button_group>
    """
  end
end
