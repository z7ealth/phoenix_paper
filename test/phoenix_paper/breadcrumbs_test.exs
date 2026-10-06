defmodule PhoenixPaper.BreadcrumbsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Breadcrumbs

  test "links every item except the one without an href/navigate/patch" do
    html = render_component(&basic/1)

    assert html =~ ~s(href="/")
    assert html =~ ~s(href="/catalog")
    assert html =~ ~s(aria-current="page")
    assert html =~ "Home"
    assert html =~ "Catalog"
    assert html =~ "Current product"
  end

  defp basic(assigns) do
    ~H"""
    <.pp_breadcrumbs>
      <:item href="/">Home</:item>
      <:item href="/catalog">Catalog</:item>
      <:item>Current product</:item>
    </.pp_breadcrumbs>
    """
  end

  test "MD3 parts: text-button links, on-surface current page, chevron separators" do
    html = render_component(&basic/1)

    assert html =~ "pp-label-large text-pp-primary"
    assert html =~ "pp-state-layer"
    assert html =~ "pp-focus-ring"
    assert html =~ "text-pp-on-surface"
    assert length(Regex.scan(~r/hero-chevron-right/, html)) == 2
    assert html =~ "rtl:rotate-180"
    refute html =~ "&gt;/&lt;"
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "text-pp-primary"
    refute html =~ "text-pp-on-surface-variant"
    assert html =~ "my-breadcrumbs"
    assert html =~ "flex flex-wrap items-center"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_breadcrumbs paperize={false} class="my-breadcrumbs">
      <:item href="/">Home</:item>
      <:item>Current</:item>
    </.pp_breadcrumbs>
    """
  end
end
