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

  test "responsive (default): a modal checkbox, an expand checkbox, the scrim and the rail as siblings" do
    html = render_component(&rail/1, variant: "responsive")

    assert html =~
             ~r/<input[^>]*id="rail-toggle"[^>]*data-pp-rail-toggle[^>]*class="peer\/modal sr-only"/

    assert html =~
             ~r/<input[^>]*id="rail-expand"[^>]*data-pp-rail-expand[^>]*class="peer\/expand sr-only"/

    assert html =~ ~s(data-pp-rail="responsive")
    assert html =~ "max-md:fixed"
    assert html =~ "md:w-24"
    assert html =~ "md:peer-checked/expand:w-[280px]"
    assert html =~ "max-md:peer-checked/modal:translate-x-0"
    [scrim] = Regex.run(~r/<label[^>]*aria-hidden="true"[^>]*>/, html)
    assert scrim =~ ~s(for="rail-toggle")
    assert scrim =~ "max-md:peer-checked/modal:block"
  end

  test "the menu button opens the modal below md and expands the rail from md" do
    html = render_component(&rail/1, variant: "responsive")

    [modal] = Regex.run(~r/<label[^>]*data-pp-rail-target="modal"[^>]*>/, html)
    assert modal =~ ~s(for="rail-toggle")
    assert modal =~ "md:hidden"

    [expand] = Regex.run(~r/<label[^>]*data-pp-rail-target="expand"[^>]*>/, html)
    assert expand =~ ~s(for="rail-expand")
    assert expand =~ "max-md:hidden"
  end

  defp rail_with(assigns) do
    ~H"""
    <.pp_navigation_rail id="rail" default_expanded={@expanded} default_open={@open}>
      <.pp_navigation_rail_item icon="hero-inbox" label="Inbox" navigate="/" />
    </.pp_navigation_rail>
    """
  end

  defp checked?(html, id) do
    [tag] = Regex.run(~r/<input[^>]*id="#{id}"[^>]*>/, html)
    tag =~ ~r/\schecked[\s>=\/]/
  end

  test "default_expanded only expands the desktop rail; the small-screen modal stays closed" do
    html = render_component(&rail_with/1, expanded: true, open: false)

    assert checked?(html, "rail-expand")
    refute checked?(html, "rail-toggle")
  end

  test "default_open opens the small-screen modal, independently" do
    html = render_component(&rail_with/1, expanded: false, open: true)

    assert checked?(html, "rail-toggle")
    refute checked?(html, "rail-expand")
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

  test "pp_navigation_rail_toggle modal_only renders only the small-screen label" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_navigation_rail_toggle for='rail' modal_only />")

    assert html =~ ~s(for="rail-toggle")
    assert html =~ "md:hidden"
    assert html =~ "hero-bars-3"
    refute html =~ "rail-expand"
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
