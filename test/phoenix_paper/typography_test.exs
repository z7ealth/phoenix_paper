defmodule PhoenixPaper.TypographyTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Typography

  test "body-large (default) renders a <p> with the role utility" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_typography>Text</.pp_typography>")

    assert html =~ "<p"
    assert html =~ "pp-body-large"
    assert html =~ ~s(data-pp-component="typography")
  end

  test "each role family picks its default tag" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_typography variant="display-large">D</.pp_typography>
      <.pp_typography variant="headline-medium">H</.pp_typography>
      <.pp_typography variant="title-large">T</.pp_typography>
      <.pp_typography variant="title-small">t</.pp_typography>
      <.pp_typography variant="label-small">L</.pp_typography>
      <.pp_typography variant="code">C</.pp_typography>
      """)

    assert html =~ ~r/<h1[^>]*pp-display-large/
    assert html =~ ~r/<h3[^>]*pp-headline-medium/
    assert html =~ ~r/<h5[^>]*pp-title-large/
    assert html =~ ~r/<h6[^>]*pp-title-small/
    assert html =~ ~r/<span[^>]*pp-label-small/
    assert html =~ ~r/<code[^>]*font-mono/
  end

  test "tag overrides the variant's tag" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_typography variant='title-large' tag='h2'>Settings</.pp_typography>"
      )

    assert html =~ ~r/<h2[^>]*pp-title-large/
  end

  test "emphasized picks the role's emphasized utility" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_typography variant="headline-small" emphasized>A</.pp_typography>
      <.pp_typography variant="label-large" emphasized>B</.pp_typography>
      """)

    assert html =~ "pp-headline-small-emphasized"
    assert html =~ "pp-label-large-emphasized"
  end

  test "color maps to a role; unset inherits" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_typography color="on-surface-variant">A</.pp_typography>
      <.pp_typography color="tertiary">B</.pp_typography>
      """)

    assert html =~ "text-pp-on-surface-variant"
    assert html =~ "text-pp-tertiary"

    plain = rendered_to_string(~H"<.pp_typography>C</.pp_typography>")
    refute plain =~ "text-pp-"
  end

  test "paperize={false} keeps the tag and the caller's class only" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_typography variant='display-small' paperize={false} class='mine'>A</.pp_typography>"
      )

    assert html =~ "<h1"
    refute html =~ "pp-display-small"
    assert html =~ "mine"
  end
end
