defmodule PhoenixPaper.TabsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Tabs
  import PhoenixPaper.Tab
  import PhoenixPaper.TabPanel

  test "renders a tablist with matching tab/panel ids and aria wiring" do
    html = render_component(&basic/1)

    assert html =~ ~s(role="tablist")
    assert html =~ ~s(role="tab")
    assert html =~ ~s(role="tabpanel")
    assert html =~ ~s(id="demo-tab-one")
    assert html =~ ~s(id="demo-panel-one")
    assert html =~ ~s(aria-controls="demo-panel-one")
    assert html =~ ~s(aria-labelledby="demo-tab-one")
  end

  defp basic(assigns) do
    ~H"""
    <.pp_tabs id="demo">
      <.pp_tab id="demo" value="one" default_selected>One</.pp_tab>
      <.pp_tab id="demo" value="two">Two</.pp_tab>
    </.pp_tabs>
    <.pp_tab_panel id="demo" value="one" default_selected>Content one</.pp_tab_panel>
    <.pp_tab_panel id="demo" value="two">Content two</.pp_tab_panel>
    """
  end

  test "default_selected picks the initially active tab/panel, others start hidden" do
    html = render_component(&basic/1)

    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-selected="false")
    assert html =~ ~r/id="demo-panel-one"[^>]*class="[^"]*\bblock\b/
    assert html =~ ~r/id="demo-panel-two"[^>]*class="[^"]*\bhidden\b/
  end

  test "color picks the active tab's indicator classes" do
    html = render_component(&secondary/1)
    assert html =~ "border-pp-secondary"
    assert html =~ "text-pp-secondary"
  end

  defp secondary(assigns) do
    ~H"""
    <.pp_tabs id="demo">
      <.pp_tab id="demo" value="one" default_selected color="secondary">One</.pp_tab>
    </.pp_tabs>
    """
  end

  test "orientation=\"vertical\" uses a right border indicator instead of a bottom one" do
    html = render_component(&vertical/1)
    assert html =~ "border-r-2"
    refute html =~ "border-b-2"
  end

  defp vertical(assigns) do
    ~H"""
    <.pp_tabs id="demo" orientation="vertical">
      <.pp_tab id="demo" value="one" orientation="vertical">One</.pp_tab>
    </.pp_tabs>
    """
  end

  test "variant=\"full_width\" stretches every tab equally" do
    html = render_component(&full_width/1)
    assert html =~ "flex-1"
  end

  defp full_width(assigns) do
    ~H"""
    <.pp_tabs id="demo" variant="full_width">
      <.pp_tab id="demo" value="one">One</.pp_tab>
    </.pp_tabs>
    """
  end

  test "disabled tab renders the disabled attribute" do
    html = render_component(&disabled/1)
    assert html =~ "disabled"
  end

  defp disabled(assigns) do
    ~H"""
    <.pp_tabs id="demo">
      <.pp_tab id="demo" value="one" disabled>One</.pp_tab>
    </.pp_tabs>
    """
  end

  test "paperize={false} renders bare elements with no built-in classes" do
    html = render_component(&bare/1)
    assert html =~ ~s(data-pp-component="tabs" class="")
    assert html =~ ~s(class="my-tab")
  end

  defp bare(assigns) do
    ~H"""
    <.pp_tabs id="demo" paperize={false}>
      <.pp_tab id="demo" value="one" paperize={false} class="my-tab">One</.pp_tab>
    </.pp_tabs>
    <.pp_tab_panel id="demo" value="one" paperize={false}>Content</.pp_tab_panel>
    """
  end

  test "select/3 builds the exact op sequence that deselects the group, then selects this tab/panel" do
    %Phoenix.LiveView.JS{ops: ops} = PhoenixPaper.Tabs.select("demo", "two", "secondary")

    assert [
             ["remove_class", %{names: all_active, to: "[data-pp-tabs-id=\"demo\"]"}],
             [
               "add_class",
               %{
                 names: ["border-transparent", "text-pp-on-surface"],
                 to: "[data-pp-tabs-id=\"demo\"]"
               }
             ],
             ["set_attr", %{to: "[data-pp-tabs-id=\"demo\"]", attr: ["aria-selected", "false"]}],
             [
               "remove_class",
               %{names: ["border-transparent", "text-pp-on-surface"], to: "#demo-tab-two"}
             ],
             [
               "add_class",
               %{names: ["border-pp-secondary", "text-pp-secondary"], to: "#demo-tab-two"}
             ],
             ["set_attr", %{to: "#demo-tab-two", attr: ["aria-selected", "true"]}],
             ["hide", %{to: "[data-pp-tab-panel-group=\"demo\"]"}],
             ["show", %{to: "#demo-panel-two", display: "block"}]
           ] = ops

    assert "border-pp-secondary" in all_active
    assert "text-pp-error" in all_active
  end

  test "icon slot renders alongside the label" do
    html = render_component(&with_icon/1)
    assert html =~ "★"
    assert html =~ "One"
  end

  defp with_icon(assigns) do
    ~H"""
    <.pp_tabs id="demo">
      <.pp_tab id="demo" value="one">
        <:icon>★</:icon>
        One
      </.pp_tab>
    </.pp_tabs>
    """
  end
end
