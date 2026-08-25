defmodule PhoenixPaper.CheckboxTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Checkbox

  test "field= populates name/id/checked from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(id="user_accepted")
    assert html =~ ~s(name="user[accepted]")
    assert html =~ "checked"
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"accepted" => "true"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_checkbox field={@form[:accepted]} label="Accept" />
    """
  end

  test "renders the hidden-input trick and the checked box when true" do
    html = render_component(&checked/1)

    assert html =~ ~s(type="hidden")
    assert html =~ ~s(type="checkbox")
    assert html =~ "checked"
    assert html =~ "Accept terms"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_checkbox checked={true} label="Accept terms" />
    """
  end

  test "paperize={false} renders a bare native checkbox, no hidden input" do
    html = render_component(&bare/1)

    refute html =~ ~s(type="hidden")
    assert html =~ ~s(type="checkbox")
  end

  defp bare(assigns) do
    ~H"""
    <.pp_checkbox paperize={false} label="Bare" />
    """
  end

  test "ripple (default): wires the click handler on the box" do
    html = render_component(&checked/1)
    assert html =~ "onclick="
  end

  test "ripple={false}: no click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_checkbox ripple={false} />
    """
  end

  test "paperize={false}: no click handler either, even though ripple defaults true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end

  test "paperize={false}: class sizes the bare input, not the label, and the label keeps its flex layout" do
    html = render_component(&bare_sized/1)

    assert html =~ ~r/<label[^>]*class="[^"]*inline-flex[^"]*items-center[^"]*"/
    assert html =~ ~r/<input[^>]*class="size-5"/
    refute html =~ ~r/<label[^>]*class="size-5"/
  end

  defp bare_sized(assigns) do
    ~H"""
    <.pp_checkbox paperize={false} label="Bare" class="size-5" />
    """
  end
end
