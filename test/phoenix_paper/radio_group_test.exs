defmodule PhoenixPaper.RadioGroupTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.RadioGroup

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
end
