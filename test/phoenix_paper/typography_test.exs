defmodule PhoenixPaper.TypographyTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Typography

  test "h1 renders an <h1> with the heading classes" do
    html = render_component(&h1/1)

    assert html =~ "<h1"
    assert html =~ "text-5xl"
    assert html =~ "Title"
  end

  defp h1(assigns) do
    ~H"""
    <.pp_typography variant="h1">Title</.pp_typography>
    """
  end

  test "body1 (the default) renders a <p>" do
    html = render_component(&default/1)
    assert html =~ "<p"
    assert html =~ "text-base"
  end

  defp default(assigns) do
    ~H"""
    <.pp_typography>Paragraph</.pp_typography>
    """
  end

  test "caption renders a <span> with dimmed text" do
    html = render_component(&caption/1)
    assert html =~ "<span"
    assert html =~ "text-pp-on-surface/70"
  end

  defp caption(assigns) do
    ~H"""
    <.pp_typography variant="caption">Hint</.pp_typography>
    """
  end

  test "code renders a <code> tag with monospace styling" do
    html = render_component(&code/1)
    assert html =~ "<code"
    assert html =~ "font-mono"
  end

  defp code(assigns) do
    ~H"""
    <.pp_typography variant="code">mix test</.pp_typography>
    """
  end

  test "paperize={false} drops the variant classes but keeps the tag and caller class" do
    html = render_component(&bare/1)
    refute html =~ "text-5xl"
    assert html =~ "<h2"
    assert html =~ "my-heading"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_typography variant="h2" paperize={false} class="my-heading">Title</.pp_typography>
    """
  end
end
