defmodule PhoenixPaper.IconButtonTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.IconButton

  test "standard (default): label as aria-label and title, 40dp, icon, state layer" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_icon_button icon='hero-heart' label='Favorite' />")

    assert html =~ ~s(aria-label="Favorite")
    assert html =~ ~s(title="Favorite")
    assert html =~ "hero-heart"
    assert html =~ "h-10 w-10"
    assert html =~ "text-pp-on-surface-variant"
    assert html =~ "pp-state-layer"
    assert html =~ ~s(data-pp-component="icon-button")
  end

  test "title={false} drops the native tooltip" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_icon_button icon='hero-heart' label='Fav' title={false} />")
    refute html =~ "title="
  end

  test "variants and widths" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_icon_button icon="hero-x-mark" label="A" variant="filled" />
      <.pp_icon_button icon="hero-x-mark" label="B" variant="tonal" width="wide" />
      <.pp_icon_button icon="hero-x-mark" label="C" variant="outlined" size="lg" width="narrow" />
      """)

    assert html =~ "bg-pp-primary text-pp-on-primary"
    assert html =~ "bg-pp-secondary-container text-pp-on-secondary-container"
    assert html =~ "h-10 w-[52px]"
    assert html =~ "border border-pp-outline-variant"
    assert html =~ "h-24 w-16"
  end

  test "toggle with selected_icon swaps glyphs off aria-pressed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_icon_button icon="hero-star" selected_icon="hero-star-solid" label="Star" toggle selected={false} />
      """)

    assert html =~ ~s(aria-pressed="false")
    assert html =~ "hero-star-solid"
    assert html =~ "[[aria-pressed=false]&gt;&amp;]:hidden"
    assert html =~ "[[aria-pressed=true]&gt;&amp;]:hidden"
    assert html =~ "aria-pressed:text-pp-primary"
  end

  test "link mode" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_icon_button icon='hero-home' label='Home' navigate='/' />")
    assert html =~ ~s(href="/")
    refute html =~ "<button"
  end

  test "paperize={false} drops classes and ripple" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_icon_button icon='hero-home' label='Home' paperize={false} class='mine' />"
      )

    refute html =~ "pp-state-layer"
    refute html =~ "onclick"
    assert html =~ "mine"
  end
end
