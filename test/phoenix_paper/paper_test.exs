defmodule PhoenixPaper.PaperTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Paper

  test "renders a flat surface with the default shape" do
    html = render_component(&default/1)

    assert html =~ "bg-pp-surface"
    assert html =~ "pp-elevation-0"
    assert html =~ "rounded-pp-md"
    assert html =~ ~s(data-pp-component="paper")
  end

  test "surface-container roles, outlined and elevation" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_paper color="surface-container-high" elevation={3}>a</.pp_paper>
      <.pp_paper color="primary-container" outlined>b</.pp_paper>
      """)

    assert html =~ "bg-pp-surface-container-high text-pp-on-surface"
    assert html =~ "pp-elevation-3"
    assert html =~ "bg-pp-primary-container text-pp-on-primary-container"
    assert html =~ "border border-pp-outline-variant"
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

  test "color picks the background/foreground pair, surface by default" do
    assigns = %{}

    assert rendered_to_string(~H"<PhoenixPaper.Paper.pp_paper>x</PhoenixPaper.Paper.pp_paper>") =~
             "bg-pp-surface text-pp-on-surface"

    for color <- ~w(primary secondary tertiary error) do
      assigns = %{color: color}

      html =
        rendered_to_string(
          ~H"<PhoenixPaper.Paper.pp_paper color={@color}>x</PhoenixPaper.Paper.pp_paper>"
        )

      assert html =~ "bg-pp-#{color} text-pp-on-#{color}"
      refute html =~ "bg-pp-surface"
    end
  end
end
