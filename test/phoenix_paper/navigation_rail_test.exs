defmodule PhoenixPaper.NavigationRailTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.NavigationRail

  defp rail(assigns) do
    ~H"""
    <.pp_navigation_rail id="rail" variant={@variant}>
      <:fab icon="hero-pencil" label="Compose" navigate="/compose" />
      <.pp_navigation_rail_item icon="hero-inbox" active_icon="hero-inbox-solid" label="Inbox" navigate="/" active badge={4} />
      <.pp_navigation_rail_item icon="hero-trash" label="Trash" navigate="/trash" badge />
    </.pp_navigation_rail>
    """
  end

  test "responsive (default): checkbox + scrim + rail as siblings, the menu button targets the checkbox" do
    html = render_component(&rail/1, variant: "responsive")

    assert html =~ ~s(id="rail-toggle")
    assert html =~ "data-pp-rail-toggle"
    assert html =~ ~s(data-pp-rail="responsive")
    assert html =~ ~s(for="rail-toggle")
    assert html =~ "max-md:fixed"
    assert html =~ "md:w-24"
    assert html =~ "md:peer-checked:w-[280px]"
    assert html =~ "max-md:peer-checked:block"
  end

  test "collapsed/expanded variants render no checkbox, scrim or menu button" do
    for variant <- ~w(collapsed expanded) do
      html = render_component(&rail/1, variant: variant)
      refute html =~ "rail-toggle"
      assert html =~ ~s(data-pp-rail="#{variant}")
    end
  end

  test "the active item gets the secondary-container indicator, aria-current and its active icon" do
    html = render_component(&rail/1, variant: "collapsed")

    assert html =~ ~s(aria-current="page")
    assert html =~ "bg-pp-secondary-container"
    assert html =~ "hero-inbox-solid"
    assert html =~ "text-pp-secondary"
  end

  test "items switch layout with the pp-rail-expanded variant" do
    html = render_component(&rail/1, variant: "responsive")

    assert html =~ "pp-rail-expanded:flex-row"
    assert html =~ "pp-rail-expanded:hidden"
    assert html =~ "pp-rail-expanded:inline"
  end

  test "badges: a count and a dot" do
    html = render_component(&rail/1, variant: "collapsed")

    assert html =~ ~r/min-w-4[^>]*>\s*4\s*</
    assert html =~ "size-1.5 rounded-full bg-pp-error"
  end

  test "the fab slot renders a FAB that extends when expanded" do
    html = render_component(&rail/1, variant: "collapsed")

    assert html =~ ~s(aria-label="Compose")
    assert html =~ "bg-pp-primary-container"
    assert html =~ "pp-rail-expanded:inline"
  end

  test "pp_navigation_rail_toggle modal_only hides from md up" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_navigation_rail_toggle for='rail' modal_only />")

    assert html =~ ~s(for="rail-toggle")
    assert html =~ "md:hidden"
    assert html =~ "hero-bars-3"
  end

  test "paperize={false} drops the rail's classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_navigation_rail id="r" variant="collapsed" paperize={false} class="mine">
        <.pp_navigation_rail_item icon="hero-inbox" label="Inbox" navigate="/" paperize={false} />
      </.pp_navigation_rail>
      """)

    refute html =~ "bg-pp-surface"
    assert html =~ "mine"
  end
end
