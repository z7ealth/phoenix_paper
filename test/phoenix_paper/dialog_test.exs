defmodule PhoenixPaper.DialogTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Dialog

  test "renders hidden by default, with the backdrop, content, and title/actions slots" do
    html = render_component(&dialog/1)

    assert html =~ ~s(id="confirm")
    assert html =~ "hidden"
    assert html =~ "Delete this item?"
    assert html =~ "This can't be undone."
    assert html =~ "Cancel"
  end

  defp dialog(assigns) do
    ~H"""
    <.pp_dialog id="confirm">
      <:title>Delete this item?</:title>
      This can't be undone.
      <:actions>Cancel</:actions>
    </.pp_dialog>
    """
  end

  test "show/1 and hide/1 return JS commands targeting the given id" do
    assert %Phoenix.LiveView.JS{} = PhoenixPaper.Dialog.show("confirm")
    assert %Phoenix.LiveView.JS{} = PhoenixPaper.Dialog.hide("confirm")

    show_json = Jason.encode!(PhoenixPaper.Dialog.show("confirm"))
    assert show_json =~ "confirm"

    hide_json = Jason.encode!(PhoenixPaper.Dialog.hide("confirm"))
    assert hide_json =~ "confirm"
  end

  test "on_cancel is wired into the outer element's data-cancel attribute" do
    html = render_component(&with_cancel/1)
    assert html =~ "data-cancel="
  end

  defp with_cancel(assigns) do
    ~H"""
    <.pp_dialog id="confirm" on_cancel={Phoenix.LiveView.JS.push("cancelled")}>
      Body
    </.pp_dialog>
    """
  end
end
