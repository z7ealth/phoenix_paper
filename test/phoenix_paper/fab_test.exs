defmodule PhoenixPaper.FabTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Fab

  test "default: 56dp, 16dp corners, primary-container, level 3 rising to 4 on hover" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_fab icon='hero-pencil' label='Compose' />")

    assert html =~ "size-14 rounded-pp-lg"
    assert html =~ "bg-pp-primary-container text-pp-on-primary-container"
    assert html =~ "pp-elevation-3"
    assert html =~ "hover:pp-elevation-4"
    assert html =~ ~s(aria-label="Compose")
    assert html =~ "hero-pencil"
  end

  test "Expressive medium and large sizes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_fab icon="hero-pencil" label="A" size="medium" />
      <.pp_fab icon="hero-pencil" label="B" size="large" />
      """)

    assert html =~ "size-20 rounded-pp-lg-increased"
    assert html =~ "size-24 rounded-pp-xl"
  end

  test "extended shows the label and drops the aria-label" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_fab icon='hero-pencil' label='Compose' extended />")

    assert html =~ ">Compose</span>"
    refute html =~ "aria-label"
    assert html =~ "pp-title-medium"
  end

  test "colors and lowered" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_fab icon="hero-pencil" label="A" color="tertiary" lowered />
      <.pp_fab icon="hero-pencil" label="B" color="surface" />
      """)

    assert html =~ "bg-pp-tertiary text-pp-on-tertiary"
    assert html =~ "pp-elevation-1"
    assert html =~ "bg-pp-surface-container-high text-pp-primary"
  end

  test "position emits a single position class" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_fab icon='hero-pencil' label='A' position='fixed' class='bottom-4' />"
      )

    assert html =~ "fixed overflow-hidden"
    refute html =~ "relative overflow-hidden"
  end

  test "ripple off when paperize is false" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_fab icon='hero-pencil' label='A' paperize={false} />")
    refute html =~ "onclick"
    refute html =~ "pp-elevation"
  end
end
