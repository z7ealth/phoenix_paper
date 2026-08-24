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
end
