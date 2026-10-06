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

  test "is an MD3 text field with a floating label and trailing icon-button steppers" do
    html = render_component(&field/1)

    assert html =~ ~s(data-pp-component="text-field")
    assert html =~ ~s(type="number")
    assert html =~ ~s(data-pp-adornment="end")
    assert html =~ ~s(aria-label="Decrease")
    assert html =~ ~s(aria-label="Increase")
    assert html =~ ~s(data-pp-component="icon-button")
    assert html =~ ~s(tabindex="-1")
    assert html =~ "<fieldset"
    assert html =~ "[appearance:textfield]"
  end

  test "min, max and step reach the input; errors show as MD3 field errors" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_number_field name="n" label="N" min="1" max="5" step="2" errors={["is too big"]} />
      """)

    [input] = Regex.run(~r/<input[^>]*type="number"[^>]*>/, html)
    assert input =~ ~s(min="1")
    assert input =~ ~s(max="5")
    assert input =~ ~s(step="2")
    assert html =~ "is too big"
    assert html =~ "text-pp-error"
  end

  test "paperize={false} drops the skin but keeps the steppers working" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_number_field name='n' label='N' paperize={false} class='mine' />"
      )

    assert html =~ "mine"
    assert html =~ "stepUp"
    refute html =~ "[appearance:textfield]"
    refute html =~ "<fieldset"
  end
end
