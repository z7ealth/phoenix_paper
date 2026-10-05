defmodule PhoenixPaper.TabsTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Tabs
  import PhoenixPaper.Tab
  import PhoenixPaper.TabPanel

  alias Phoenix.LiveView.JS

  defp group(assigns) do
    ~H"""
    <.pp_tabs id="t" variant={@variant}>
      <.pp_tab id="t" value="one" default_selected>One</.pp_tab>
      <.pp_tab id="t" value="two" badge={3}>
        <:icon><span class="hero-photo" /></:icon>
        Two
      </.pp_tab>
      <.pp_tab id="t" value="three" disabled>Three</.pp_tab>
    </.pp_tabs>
    <.pp_tab_panel id="t" value="one" default_selected>Panel one</.pp_tab_panel>
    <.pp_tab_panel id="t" value="two">Panel two</.pp_tab_panel>
    """
  end

  test "tablist, tabs and panels are wired with matching ids and aria" do
    html = render_component(&group/1, variant: "primary")

    assert html =~ ~s(role="tablist")
    assert html =~ ~s(id="t-tab-one")
    assert html =~ ~s(aria-controls="t-panel-one")
    assert html =~ ~s(aria-labelledby="t-tab-one")
    assert html =~ ~s(data-pp-tabs-id="t")
    assert html =~ ~s(data-pp-tab-panel-group="t")
  end

  test "default_selected: aria-selected true and the only visible panel (hidden class, not attribute)" do
    html = render_component(&group/1, variant: "primary")

    assert html =~ ~r/id="t-tab-one"[^>]*aria-selected="true"/
    assert html =~ ~r/id="t-tab-two"[^>]*aria-selected="false"/
    assert html =~ ~r/id="t-panel-two"[^>]*class="hidden/
    refute html =~ ~r/id="t-panel-one"[^>]*class="hidden/
  end

  test "variant lives on the root; tabs style off it and off aria-selected" do
    html = render_component(&group/1, variant: "secondary")

    assert html =~ ~s(data-pp-variant="secondary")
    assert html =~ "group/tabs"
    assert html =~ "group-data-[pp-variant=primary]/tabs:aria-selected:text-pp-primary"
    assert html =~ "group-data-[pp-variant=secondary]/tabs:aria-selected:text-pp-on-surface"
    assert html =~ "data-pp-tab-indicator"
    assert html =~ "rounded-t-[3px]"
  end

  test "a tab with an icon is 64dp on primary tabs; badge renders" do
    html = render_component(&group/1, variant: "primary")

    assert html =~ "group-data-[pp-variant=primary]/tabs:h-16"
    assert html =~ "data-pp-tab-icon"
    assert html =~ ~r/min-w-4[^>]*>\s*3\s*</
  end

  test "disabled tab" do
    html = render_component(&group/1, variant: "primary")
    assert html =~ ~r/id="t-tab-three"[^>]*disabled/
  end

  test "layout=scrollable scrolls instead of stretching" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_tabs id='s' layout='scrollable'><span /></.pp_tabs>")
    assert html =~ "overflow-x-auto"
    refute html =~ "flex-1"
  end

  test "select/2 builds the exact op sequence" do
    assert select("t", "two").ops == [
             ["set_attr", %{to: ~s([data-pp-tabs-id="t"]), attr: ["aria-selected", "false"]}],
             ["set_attr", %{to: ~s([data-pp-tabs-id="t"]), attr: ["tabindex", "-1"]}],
             ["set_attr", %{to: "#t-tab-two", attr: ["aria-selected", "true"]}],
             ["set_attr", %{to: "#t-tab-two", attr: ["tabindex", "0"]}],
             ["hide", %{to: ~s([data-pp-tab-panel-group="t"])}],
             ["show", %{to: "#t-panel-two", display: "block"}]
           ]

    assert %JS{} = select("t", "one")
  end

  test "paperize={false} renders bare elements" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_tabs id="b" paperize={false} class="mine">
        <.pp_tab id="b" value="x" paperize={false}>X</.pp_tab>
      </.pp_tabs>
      """)

    refute html =~ "border-pp-surface-variant"
    refute html =~ "pp-title-small"
    assert html =~ "mine"
  end

  test "roving tabindex and the arrow-key handler on the tablist" do
    html = render_component(&group/1, variant: "primary")

    assert html =~ ~r/id="t-tab-one"[^>]*tabindex="0"/
    assert html =~ ~r/id="t-tab-two"[^>]*tabindex="-1"/
    assert html =~ "ArrowRight"
    assert html =~ "onkeydown="
  end
end
