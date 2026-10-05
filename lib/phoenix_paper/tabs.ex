defmodule PhoenixPaper.Tabs do
  @moduledoc """
  MD3 tabs (`pp_tabs/1`) — composed with `PhoenixPaper.Tab` (a tab) and
  `PhoenixPaper.TabPanel` (its content, usually written after the whole
  `pp_tabs/1` block):

      <.pp_tabs id="demo-tabs">
        <.pp_tab id="demo-tabs" value="one" default_selected>One</.pp_tab>
        <.pp_tab id="demo-tabs" value="two">Two</.pp_tab>
      </.pp_tabs>

      <.pp_tab_panel id="demo-tabs" value="one" default_selected>Content one</.pp_tab_panel>
      <.pp_tab_panel id="demo-tabs" value="two">Content two</.pp_tab_panel>

  Every tab and panel in a group needs the **same** `id` as its
  `pp_tabs/1` — it's how `select/2` builds its selectors — and each tab's
  `value` matches exactly one panel's.

  ## Variants

  - `primary` (default): for top-level content under the top app bar. The
    active indicator is 3dp, rounded on top, and only as wide as the
    label; the active label is `primary`. A tab with an `:icon` stacks it
    above the label (64dp tall).
  - `secondary`: for a sub-section. The indicator is 2dp and spans the
    whole tab; the active label stays `on-surface`; icons sit inline.

  `layout` is `fixed` (default; tabs share the width equally) or
  `scrollable` (tabs size to their labels and the row scrolls).

  ## How it works

  Selection is the `aria-selected` attribute and nothing else: every
  selected look (label color, indicator) is an `aria-selected:` style, so
  `select/2` only flips attributes and shows/hides panels with
  `Phoenix.LiveView.JS` — no class bookkeeping, no server round trip, and
  nothing a later patch resets (LiveView keeps JS-command attributes).

  ## Keyboard

  The ARIA tabs pattern: only the selected tab is in the Tab order
  (roving `tabindex`, kept in sync by `select/2`), and once focus is in
  the tablist, Left/Right move to the previous/next tab (wrapping, and
  mirrored in right-to-left layouts), Home/End to the first/last,
  skipping disabled tabs. A tab is selected as it receives focus
  (automatic activation). It's a small inline `onkeydown` on the tablist
  that focuses and clicks the target tab, so no hook or LiveComponent is
  needed and it works on controller-rendered pages as long as the
  LiveView JS client is loaded. Mark exactly one tab `default_selected`,
  or none will be reachable with Tab.
  `Tab`/`TabPanel` read the variant from this root through a
  `group/tabs` data attribute, so it's set once, here.

  With the PhoenixPaper JS hook (see `PhoenixPaper.Helpers.hook/1`) the
  indicator **slides** from the old tab to the new one on the Expressive
  spatial spring; without it, it moves instantly. MD3's roving `tabindex`
  is implemented, see Keyboard below.

  ## Migrating from 0.3

  `variant="standard"/"full_width"` → `layout="fixed"`, `"scrollable"` →
  `layout="scrollable"`; the new `variant` picks primary/secondary.
  `orientation="vertical"` and per-tab `color` are gone (MD3 has neither).
  `select/3` is now `select/2`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  attr(:id, :string, required: true, doc: "shared with every Tab/TabPanel in the group")
  attr(:variant, :string, default: "primary", values: ~w(primary secondary))
  attr(:layout, :string, default: "fixed", values: ~w(fixed scrollable))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-label aria-labelledby))

  slot(:inner_block, required: true)

  # ARIA tabs keyboard model: arrows move to the previous/next enabled tab
  # (wrapping, mirrored in RTL), Home/End to the first/last, and the tab
  # is selected as it gets focus (automatic activation) by clicking it,
  # which runs select/2.
  @keyboard_js "var k=event.key,t=Array.prototype.slice.call(this.querySelectorAll('[role=tab]:not([disabled])')),i=t.indexOf(document.activeElement);if(i<0)return;var rtl=getComputedStyle(this).direction==='rtl',n=null;if(k==='ArrowRight')n=rtl?i-1:i+1;else if(k==='ArrowLeft')n=rtl?i+1:i-1;else if(k==='Home')n=0;else if(k==='End')n=t.length-1;if(n===null)return;event.preventDefault();n=(n+t.length)%t.length;t[n].focus();t[n].click();"

  @doc "Renders a tablist. See the module doc."
  def pp_tabs(assigns) do
    assigns = assign(assigns, :keyboard_js, @keyboard_js)

    ~H"""
    <div
      id={"#{@id}-tablist"}
      role="tablist"
      data-pp-component="tabs"
      data-pp-variant={@variant}
      phx-hook={Helpers.hook()}
      onkeydown={@keyboard_js}
      class={Helpers.classes(@paperize, paper_classes(@layout), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc false
  def tab_id(id, value), do: "#{id}-tab-#{value}"

  @doc false
  def panel_id(id, value), do: "#{id}-panel-#{value}"

  @doc """
  A `Phoenix.LiveView.JS` command selecting tab/panel `value` in the `id`
  group: marks every tab in the group `aria-selected="false"`, this one
  `"true"`, hides every panel and shows the matching one. Wired to every
  `pp_tab/1`'s click; public so a trigger elsewhere (a "next" button) can
  switch tabs too, the way `PhoenixPaper.Dialog.show/2` opens a dialog.
  """
  @spec select(String.t(), String.t()) :: JS.t()
  def select(id, value) do
    %JS{}
    |> JS.set_attribute({"aria-selected", "false"}, to: "[data-pp-tabs-id=\"#{id}\"]")
    |> JS.set_attribute({"tabindex", "-1"}, to: "[data-pp-tabs-id=\"#{id}\"]")
    |> JS.set_attribute({"aria-selected", "true"}, to: "##{tab_id(id, value)}")
    |> JS.set_attribute({"tabindex", "0"}, to: "##{tab_id(id, value)}")
    |> JS.hide(to: "[data-pp-tab-panel-group=\"#{id}\"]")
    |> JS.show(to: "##{panel_id(id, value)}", display: "block")
  end

  defp paper_classes("fixed"),
    do:
      "group/tabs flex items-stretch border-b border-pp-surface-variant [&>[data-pp-component=tab]]:flex-1"

  defp paper_classes("scrollable"),
    do:
      "group/tabs flex items-stretch overflow-x-auto border-b border-pp-surface-variant [scrollbar-width:none]"
end
