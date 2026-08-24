defmodule PhoenixPaper.NumberFieldTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.NumberField

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
