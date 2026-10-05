defmodule PhoenixPaper.SnackbarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Snackbar

  test "renders the inverted-surface chip with the message and an optional action" do
    html = render_component(&snackbar/1)

    assert html =~ "bg-pp-inverse-surface"
    assert html =~ "text-pp-inverse-on-surface"
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

  test "sits at the bottom: centered on compact screens, bottom-start from sm" do
    html = render_component(&snackbar/1)

    assert html =~ "fixed inset-x-4 bottom-4 sm:inset-x-auto sm:start-6 sm:bottom-6"
    refute html =~ "top-4"
  end

  test "enters with MD3's single entrance animation" do
    assert render_component(&snackbar/1) =~ "pp-snackbar-enter"
  end

  test "on_close renders the trailing close button wired to the given JS" do
    html = render_component(&closable/1)

    assert html =~ "data-pp-snackbar-close"
    assert html =~ ~s(aria-label="Close")
    assert html =~ "phx-click"
  end

  defp closable(assigns) do
    ~H"""
    <.pp_snackbar on_close={Phoenix.LiveView.JS.push("dismiss")}>Saved</.pp_snackbar>
    """
  end

  test "auto_hide_duration renders the CSS-timer span only when on_close is also set" do
    html = render_component(&auto_hide/1)
    assert html =~ "pp-snackbar-timeout"
    assert html =~ "--pp-snackbar-timeout: 4000ms"
    assert html =~ "onanimationend"

    refute render_component(&auto_hide_no_close/1) =~ "pp-snackbar-timeout"
  end

  defp auto_hide(assigns) do
    ~H"""
    <.pp_snackbar auto_hide_duration={4000} on_close={Phoenix.LiveView.JS.push("dismiss")}>
      Saved
    </.pp_snackbar>
    """
  end

  defp auto_hide_no_close(assigns) do
    ~H"""
    <.pp_snackbar auto_hide_duration={4000}>Saved</.pp_snackbar>
    """
  end

  test "positioned={false} keeps the chip styling but drops the fixed anchor classes" do
    html = render_component(&unpositioned/1)

    assert html =~ "bg-pp-inverse-surface"
    refute html =~ "fixed"
  end

  defp unpositioned(assigns) do
    ~H"""
    <.pp_snackbar positioned={false}>Saved</.pp_snackbar>
    """
  end

  test "paperize={false} keeps the timer animation functional but strips the visible bar's size/color" do
    html = render_component(&bare_with_timer/1)

    assert html =~ "pp-snackbar-timeout"
    refute html =~ "bg-pp-inverse-primary/60"
    refute html =~ "inset-x-0"
  end

  defp bare_with_timer(assigns) do
    ~H"""
    <.pp_snackbar
      paperize={false}
      auto_hide_duration={4000}
      on_close={Phoenix.LiveView.JS.push("dismiss")}
    >
      Saved
    </.pp_snackbar>
    """
  end
end
