defmodule PhoenixPaper.SwitchTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Switch

  test "field= populates name/id/checked from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(id="user_wifi")
    assert html =~ ~s(name="user[wifi]")
    assert html =~ "checked"
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"wifi" => "true"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_switch field={@form[:wifi]} label="Wi-Fi" />
    """
  end

  test "checked switch gets the checked-state classes via has-[:checked], not peer-checked" do
    html = render_component(&checked/1)

    assert html =~ "has-[:checked]:bg-pp-primary/50"
    assert html =~ "checked"
  end

  defp checked(assigns) do
    ~H"""
    <.pp_switch name="wifi" checked={true} label="Wi-Fi" />
    """
  end

  test "paperize={false} renders a bare checkbox" do
    html = render_component(&bare/1)
    refute html =~ "has-[:checked]"
    assert html =~ "my-switch"
  end

  test "paperize={false}: class lands on the bare input, not the label, which keeps its flex layout" do
    html = render_component(&bare/1)

    assert html =~ ~r/<label[^>]*class="[^"]*inline-flex[^"]*items-center[^"]*"/
    assert html =~ ~r/<input[^>]*class="my-switch"/
    refute html =~ ~r/<label[^>]*class="my-switch"/
  end

  defp bare(assigns) do
    ~H"""
    <.pp_switch paperize={false} name="wifi" class="my-switch" />
    """
  end

  test "ripple (default): wires the click handler on the track" do
    html = render_component(&checked/1)
    assert html =~ "onclick="
  end

  test "ripple={false}: no click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_switch name="wifi" ripple={false} />
    """
  end

  test "paperize={false}: no click handler either, even though ripple defaults true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end
end
