defmodule PhoenixPaper.NumberFieldTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.NumberField

  test "field= populates name/id/value from the form field" do
    html = render_component(&with_form_field/1)

    assert html =~ ~s(id="user_qty")
    assert html =~ ~s(name="user[qty]")
    assert html =~ ~s(value="3")
  end

  defp with_form_field(assigns) do
    form = Phoenix.Component.to_form(%{"qty" => "3"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_number_field field={@form[:qty]} label="Quantity" />
    """
  end

  test "renders stepper buttons wired to the input's id via stepUp/stepDown" do
    html = render_component(&field/1)

    assert html =~ "getElementById(&quot;qty&quot;)"
    assert html =~ "stepUp"
    assert html =~ "stepDown"
    assert html =~ ~s(id="qty")
  end

  defp field(assigns) do
    ~H"""
    <.pp_number_field id="qty" name="qty" label="Quantity" value={2} />
    """
  end

  test "stepper buttons show a pointer cursor on hover" do
    html = render_component(&field/1)
    assert html =~ "cursor-pointer"
  end
end
