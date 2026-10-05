defmodule PhoenixPaper.AccordionTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Accordion
  import PhoenixPaper.AccordionSummary
  import PhoenixPaper.AccordionDetails
  import PhoenixPaper.AccordionActions

  test "renders a checkbox (independent, not exclusive) by default" do
    html = render_component(&accordion/1)

    assert html =~ ~s(type="checkbox")
    assert html =~ ~s(id="acc1-toggle")
    refute html =~ ~s(type="radio")
  end

  defp accordion(assigns) do
    ~H"""
    <.pp_accordion id="acc1">
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  test "name given: renders a radio for exclusive-group behavior" do
    html = render_component(&exclusive/1)

    assert html =~ ~s(type="radio")
    assert html =~ ~s(name="faq")
  end

  defp exclusive(assigns) do
    ~H"""
    <.pp_accordion id="acc1" name="faq">
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  test "default_expanded sets the initial checked state" do
    html = render_component(&expanded/1)
    assert html =~ "checked"
  end

  defp expanded(assigns) do
    ~H"""
    <.pp_accordion id="acc1" default_expanded>
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  test "disabled disables the checkbox" do
    html = render_component(&disabled/1)
    assert html =~ "disabled"
  end

  defp disabled(assigns) do
    ~H"""
    <.pp_accordion id="acc1" disabled>
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  test "summary is a label pointing at the accordion's toggle id" do
    html = render_component(&accordion/1)
    assert html =~ ~s(for="acc1-toggle")
  end

  test "details and actions are hidden by default, shown via peer-checked" do
    html = render_component(&with_actions/1)

    assert html =~ "peer-checked:block"
    assert html =~ "peer-checked:flex"
  end

  defp with_actions(assigns) do
    ~H"""
    <.pp_accordion id="acc1">
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
      <.pp_accordion_actions id="acc1">Cancel</.pp_accordion_actions>
    </.pp_accordion>
    """
  end

  test "disable_gutters drops the has-[:checked]:my-2 margin" do
    html = render_component(&accordion/1)
    assert html =~ "my-2"

    html = render_component(&no_gutters/1)
    refute html =~ "my-2"
  end

  defp no_gutters(assigns) do
    ~H"""
    <.pp_accordion id="acc1" disable_gutters>
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  test "paperize={false} on accordion: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-surface"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_accordion id="acc1" paperize={false} class="my-class">
      <.pp_accordion_summary id="acc1">Header</.pp_accordion_summary>
      <.pp_accordion_details id="acc1">Body</.pp_accordion_details>
    </.pp_accordion>
    """
  end

  describe "colors and styles" do
    defp styled(assigns) do
      ~H"""
      <.pp_accordion id="s" variant={@variant} color={@color}>
        <.pp_accordion_summary id="s">H</.pp_accordion_summary>
      </.pp_accordion>
      """
    end

    defp root(variant, color) do
      html = render_component(&styled/1, variant: variant, color: color)
      [root] = Regex.run(~r/<div[^>]*data-pp-component="accordion"[^>]*>/, html)
      root
    end

    test "defaults: elevated, surface-container-low, elevation 1" do
      root = root("elevated", "default")
      assert root =~ "bg-pp-surface-container-low text-pp-on-surface"
      assert root =~ "pp-elevation-1"
      assert root =~ ~s(data-pp-variant="elevated")
      refute root =~ "border"
    end

    test "elevated/filled with a color fill the panel with the container role and tint the dividers" do
      for color <- ~w(primary secondary tertiary error) do
        elevated = root("elevated", color)
        assert elevated =~ "bg-pp-#{color}-container text-pp-on-#{color}-container"
        assert elevated =~ "pp-elevation-1"
        assert elevated =~ "accordion-details]]:border-pp-on-#{color}-container/20"

        filled = root("filled", color)
        assert filled =~ "bg-pp-#{color}-container"
        assert filled =~ "pp-elevation-0"
      end

      assert root("filled", "default") =~ "bg-pp-surface-container-highest"
    end

    test "outlined keeps the surface, borders it and colors the summary" do
      assert root("outlined", "default") =~ "border border-pp-outline-variant"

      for color <- ~w(primary secondary tertiary error) do
        root = root("outlined", color)
        assert root =~ "bg-pp-surface"
        assert root =~ "pp-elevation-0"
        assert root =~ "border border-pp-#{color}"
        assert root =~ "accordion-summary]]:text-pp-#{color}"
      end
    end
  end
end
