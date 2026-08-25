defmodule PhoenixPaper.SnackbarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Snackbar

  test "renders the inverted-surface chip with the message and an optional action" do
    html = render_component(&snackbar/1)

    assert html =~ "bg-pp-on-surface"
    assert html =~ "text-pp-surface"
    assert html =~ "Changes saved"
    assert html =~ "Undo"
  end

  defp snackbar(assigns) do
    ~H"""
    <.pp_snackbar>
      Changes saved
      <:action>Undo</:action>
    </.pp_snackbar>
    """
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-on-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_snackbar paperize={false} class="my-class">Changes saved</.pp_snackbar>
    """
  end

  test "open={false}: renders nothing at all" do
    html = render_component(&closed/1)
    assert String.trim(html) == ""
  end

  defp closed(assigns) do
    ~H"""
    <.pp_snackbar open={false}>Changes saved</.pp_snackbar>
    """
  end

  test "anchor_origin (default bottom-left) positions bottom-left" do
    html = render_component(&snackbar/1)

    assert html =~ "bottom-4"
    assert html =~ "left-4"
  end

  test "anchor_origin=\"top-right\" positions top-right instead" do
    html = render_component(&top_right/1)

    assert html =~ "top-4"
    assert html =~ "right-4"
    refute html =~ "bottom-4"
  end

  defp top_right(assigns) do
    ~H"""
    <.pp_snackbar anchor_origin="top-right">Changes saved</.pp_snackbar>
    """
  end

  test "anchor_origin=\"bottom-center\" centers via a transform" do
    html = render_component(&bottom_center/1)
    assert html =~ "-translate-x-1/2"
  end

  defp bottom_center(assigns) do
    ~H"""
    <.pp_snackbar anchor_origin="bottom-center">Changes saved</.pp_snackbar>
    """
  end

  test "transition (default: grow)" do
    html = render_component(&snackbar/1)
    assert html =~ "pp-snackbar-grow"
  end

  test "transition=\"slide\" picks the direction from anchor_origin's vertical edge" do
    html = render_component(&slide_top/1)
    assert html =~ "pp-snackbar-slide-down"

    html = render_component(&slide_bottom/1)
    assert html =~ "pp-snackbar-slide-up"
  end

  defp slide_top(assigns) do
    ~H"""
    <.pp_snackbar anchor_origin="top-left" transition="slide">Changes saved</.pp_snackbar>
    """
  end

  defp slide_bottom(assigns) do
    ~H"""
    <.pp_snackbar anchor_origin="bottom-left" transition="slide">Changes saved</.pp_snackbar>
    """
  end

  test "transition=\"none\" has no animation class" do
    html = render_component(&no_transition/1)

    refute html =~ "pp-snackbar-fade"
    refute html =~ "pp-snackbar-grow"
    refute html =~ "pp-snackbar-slide"
  end

  defp no_transition(assigns) do
    ~H"""
    <.pp_snackbar transition="none">Changes saved</.pp_snackbar>
    """
  end
end
