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

  test "renders the default \"/\" separator between items" do
    html = render_component(&basic/1)
    assert html =~ ~r/aria-hidden="true"[^>]*>\s*\/\s*</
  end

  test "a custom separator slot overrides the default \"/\"" do
    html = render_component(&custom_separator/1)
    refute html =~ ~r/aria-hidden="true"[^>]*>\s*\/\s*</
    assert html =~ "&gt;"
  end

  defp custom_separator(assigns) do
    ~H"""
    <.pp_breadcrumbs>
      <:separator>&gt;</:separator>
      <:item href="/">Home</:item>
      <:item>Current</:item>
    </.pp_breadcrumbs>
    """
  end

  test "under max_items, renders every item with no collapse checkbox" do
    html = render_component(&basic/1)
    refute html =~ "peer sr-only"
    refute html =~ "&hellip;"
  end

  test "beyond max_items, collapses to before/ellipsis/after with an expand checkbox" do
    html = render_component(&collapsed/1)

    assert html =~ "&hellip;"
    assert html =~ ~s(type="checkbox")
    assert html =~ "peer-checked:hidden"
    assert html =~ "peer-checked:flex"
    # collapsed view shows first + last only
    assert html =~ "One"
    refute html =~ ~r/peer-checked:hidden[^<]*<[^>]*>\s*Two/s
    # full view (always rendered, just hidden) has everything
    assert html =~ "Two"
    assert html =~ "Three"
    assert html =~ "Four"
  end

  defp collapsed(assigns) do
    ~H"""
    <.pp_breadcrumbs max_items={3}>
      <:item href="/one">One</:item>
      <:item href="/two">Two</:item>
      <:item href="/three">Three</:item>
      <:item>Four</:item>
    </.pp_breadcrumbs>
    """
  end

  test "items_before_collapse / items_after_collapse control the collapsed slice sizes" do
    html = render_component(&custom_slice/1)
    assert html =~ "&hellip;"
    assert html =~ "One"
    assert html =~ "Two"
  end

  defp custom_slice(assigns) do
    ~H"""
    <.pp_breadcrumbs max_items={3} items_before_collapse={2} items_after_collapse={1}>
      <:item href="/one">One</:item>
      <:item href="/two">Two</:item>
      <:item href="/three">Three</:item>
      <:item>Four</:item>
    </.pp_breadcrumbs>
    """
  end

  test "expand_text sets the ellipsis control's aria-label" do
    html = render_component(&expand_text/1)
    assert html =~ ~s(aria-label="Show full path")
  end

  defp expand_text(assigns) do
    ~H"""
    <.pp_breadcrumbs max_items={2} expand_text="Show full path">
      <:item href="/one">One</:item>
      <:item href="/two">Two</:item>
      <:item>Three</:item>
    </.pp_breadcrumbs>
    """
  end

  test "paperize={false} drops built-in classes" do
    html = render_component(&bare/1)
    refute html =~ "text-pp-primary"
    assert html =~ "my-breadcrumbs"
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
