defmodule PhoenixPaper.FormTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Form
  import PhoenixPaper.Input

  defp live_form(assigns) do
    assigns = assign(assigns, :form, to_form(%{"email" => "a@b.c"}, as: :user))

    ~H"""
    <.pp_form :let={f} for={@form} id="user-form" phx-change="validate" phx-submit="save">
      <.pp_input field={f[:email]} label="Email" />
      <:actions><button type="submit">Save</button></:actions>
    </.pp_form>
    """
  end

  test "renders a Phoenix form with the column layout, rest attrs and :let form" do
    html = render_component(&live_form/1)

    assert html =~ ~s(<form)
    assert html =~ ~s(data-pp-component="form")
    assert html =~ ~s(id="user-form")
    assert html =~ ~s(phx-submit="save")
    assert html =~ ~s(phx-change="validate")
    assert html =~ "flex flex-col gap-4"
    assert html =~ ~s(name="user[email]")
    assert html =~ ~s(value="a@b.c")
  end

  test "renders :actions right-aligned after the fields" do
    html = render_component(&live_form/1)

    assert html =~ ~s(class="flex flex-wrap items-center justify-end gap-2")
    [fields, actions] = String.split(html, "justify-end", parts: 2)
    assert fields =~ "user[email]"
    assert actions =~ "Save"
  end

  defp dead_form(assigns) do
    ~H"""
    <.pp_form for={%{}} as={:session} action="/session" method="delete" csrf_token="tok" multipart>
      <input name="session[x]" />
    </.pp_form>
    """
  end

  test "action/method/csrf_token/multipart go through Phoenix's form" do
    html = render_component(&dead_form/1)

    assert html =~ ~s(action="/session")
    assert html =~ ~s(method="post")
    assert html =~ ~s(name="_method")
    assert html =~ ~s(value="delete")
    assert html =~ ~s(value="tok")
    assert html =~ ~s(enctype="multipart/form-data")
    refute html =~ "justify-end"
  end

  defp spaced(assigns) do
    ~H"""
    <.pp_form for={%{}} spacing={:lg}>x</.pp_form>
    """
  end

  test "spacing picks the gap" do
    html = render_component(&spaced/1)
    assert html =~ "gap-6"
    refute html =~ "gap-4"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_form for={%{}} paperize={false} class="my-form">x</.pp_form>
    """
  end

  test "paperize={false} drops the layout, keeps the caller class" do
    html = render_component(&bare/1)
    assert html =~ ~s(class="my-form")
    refute html =~ "flex-col"
  end
end
