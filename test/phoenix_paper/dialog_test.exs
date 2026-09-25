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

  describe "max_width" do
    defp content_tag(html) do
      [tag] = Regex.run(~r/<div[^>]*data-pp-component="dialog-content"[^>]*>/, html)
      tag
    end

    test "defaults to md, the previous fixed width" do
      assigns = %{}

      html =
        rendered_to_string(
          ~H"<PhoenixPaper.Dialog.pp_dialog id='d'>x</PhoenixPaper.Dialog.pp_dialog>"
        )

      assert content_tag(html) =~ "w-full p-6 max-w-md"
    end

    test "maps each value to a literal max-w class" do
      for {value, class} <- [
            {"xs", "max-w-xs"},
            {"sm", "max-w-sm"},
            {"lg", "max-w-lg"},
            {"2xl", "max-w-2xl"},
            {"5xl", "max-w-5xl"},
            {"full", "max-w-full"}
          ] do
        assigns = %{value: value}

        html =
          rendered_to_string(
            ~H"<PhoenixPaper.Dialog.pp_dialog id='d' max_width={@value}>x</PhoenixPaper.Dialog.pp_dialog>"
          )

        tag = content_tag(html)
        assert tag =~ class
        refute tag =~ "max-w-md"
      end
    end
  end
end
