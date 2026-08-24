defmodule PhoenixPaper.DividerTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Divider

  test "renders an hr with the default full-width classes" do
    html = render_component(&divider/1)

    assert html =~ "<hr"
    refute html =~ "ml-14"
  end

  defp divider(assigns) do
    ~H"""
    <.pp_divider />
    """
  end

  test "inset adds a left margin to align past a leading icon column" do
    html = render_component(&inset/1)
    assert html =~ "ml-14"
  end

  defp inset(assigns) do
    ~H"""
    <.pp_divider inset />
    """
  end
end
