defmodule PhoenixPaper.SelectTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Select

  test "renders options and selects the matching value" do
    html = render_component(&select/1)

    assert html =~ "Canada"
    assert html =~ "Mexico"
    assert html =~ ~s(value="mx")
    assert html =~ "selected"
  end

  defp select(assigns) do
    ~H"""
    <.pp_select name="country" label="Country" value="mx" options={[{"Canada", "ca"}, {"Mexico", "mx"}]} />
    """
  end

  test "renders error classes instead of the outline color when errors are present" do
    html = render_component(&with_errors/1)

    assert html =~ "border-pp-error"
    assert html =~ "required"
  end

  defp with_errors(assigns) do
    ~H"""
    <.pp_select name="country" label="Country" options={["ca", "mx"]} errors={["required"]} />
    """
  end

  test "shows a pointer cursor on hover" do
    html = render_component(&select/1)
    assert html =~ "cursor-pointer"
  end
end
