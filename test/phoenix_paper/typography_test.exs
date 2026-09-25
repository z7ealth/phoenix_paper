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

  describe "color" do
    test "unset inherits, except caption which stays muted" do
      assigns = %{}

      body =
        rendered_to_string(
          ~H"<PhoenixPaper.Typography.pp_typography>x</PhoenixPaper.Typography.pp_typography>"
        )

      refute body =~ "text-pp-"

      caption =
        rendered_to_string(
          ~H"<PhoenixPaper.Typography.pp_typography variant='caption'>x</PhoenixPaper.Typography.pp_typography>"
        )

      assert caption =~ "text-pp-on-surface/70"
    end

    test "maps each color to a theme text class" do
      for {color, class} <- [
            {"primary", "text-pp-primary"},
            {"secondary", "text-pp-secondary"},
            {"accent", "text-pp-accent"},
            {"error", "text-pp-error"},
            {"muted", "text-pp-on-surface/70"}
          ] do
        assigns = %{color: color}

        html =
          rendered_to_string(
            ~H"<PhoenixPaper.Typography.pp_typography variant='overline' color={@color}>x</PhoenixPaper.Typography.pp_typography>"
          )

        assert html =~ class
      end
    end

    test "a color on caption replaces its muted default" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H"<PhoenixPaper.Typography.pp_typography variant='caption' color='primary'>x</PhoenixPaper.Typography.pp_typography>"
        )

      assert html =~ "text-pp-primary"
      refute html =~ "text-pp-on-surface/70"
    end
  end

  test "caption and overline are block-level spans, button stays inline" do
    for {variant, block?} <- [{"caption", true}, {"overline", true}, {"button", false}] do
      assigns = %{variant: variant}

      html =
        rendered_to_string(
          ~H"<PhoenixPaper.Typography.pp_typography variant={@variant}>x</PhoenixPaper.Typography.pp_typography>"
        )

      assert html =~ "<span"
      assert Regex.match?(~r/class="block /, html) == block?
    end
  end
end
