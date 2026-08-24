defmodule PhoenixPaper.GridTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Grid

  test "renders a 12-column grid with the default spacing" do
    html = render_component(&grid/1)

    assert html =~ "grid-cols-12"
    assert html =~ "gap-4"
  end

  defp grid(assigns) do
    ~H"""
    <.pp_grid>Content</.pp_grid>
    """
  end
end
