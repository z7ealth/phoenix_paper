defmodule PhoenixPaper.PaperTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Paper

  test "renders a surface with the default elevation and shape" do
    html = render_component(&default/1)

    assert html =~ "bg-pp-surface"
    assert html =~ "pp-elevation-1"
    assert html =~ ~s(data-pp-component="paper")
  end

  defp default(assigns) do
    ~H"""
    <.pp_paper>Content</.pp_paper>
    """
  end

  test "component overrides the data-pp-component marker (used by Card)" do
    html = render_component(&overridden/1)

    assert html =~ ~s(data-pp-component="card")
    refute html =~ ~s(data-pp-component="paper")
  end

  defp overridden(assigns) do
    ~H"""
    <.pp_paper component="card">Content</.pp_paper>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "bg-pp-surface"
    assert html =~ "my-paper"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_paper paperize={false} class="my-paper">Content</.pp_paper>
    """
  end
end
