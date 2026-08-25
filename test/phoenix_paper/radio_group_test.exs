defmodule PhoenixPaper.RadioGroupTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.RadioGroup

  test "field= populates name/value from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(name="user[size]")
    assert html =~ "checked"
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"size" => "md"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_radio_group field={@form[:size]} options={["sm", "md", "lg"]} />
    """
  end

  test "renders one radio per option and checks the matching value" do
    html = render_component(&group/1)

    assert html =~ "Small"
    assert html =~ "Medium"
    assert html =~ "Large"
    assert html =~ ~s(value="md")
    assert html =~ "checked"
  end

  defp group(assigns) do
    ~H"""
    <.pp_radio_group name="size" label="Size" value="md" options={[{"Small", "sm"}, {"Medium", "md"}, {"Large", "lg"}]} />
    """
  end

  test "plain string options are used as both label and value" do
    html = render_component(&plain/1)
    assert html =~ "Red"
    assert html =~ ~s(value="Red")
  end

  defp plain(assigns) do
    ~H"""
    <.pp_radio_group name="color" options={["Red", "Green"]} />
    """
  end

  test "ripple (default): wires the click handler on each option's box" do
    html = render_component(&group/1)
    assert html =~ "onclick="
  end

  test "ripple={false}: no click handler" do
    html = render_component(&no_ripple/1)
    refute html =~ "onclick="
  end

  defp no_ripple(assigns) do
    ~H"""
    <.pp_radio_group name="size" ripple={false} options={["sm", "md"]} />
    """
  end

  test "paperize={false}: no click handler either, even though ripple defaults true" do
    html = render_component(&bare/1)
    refute html =~ "onclick="
  end

  defp bare(assigns) do
    ~H"""
    <.pp_radio_group name="size" paperize={false} options={["sm", "md"]} />
    """
  end
end
