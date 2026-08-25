defmodule PhoenixPaper.Tabs do
  @moduledoc """
  A tablist container (`pp_tabs/1`), in the spirit of MUI's `Tabs` —
  composed with `PhoenixPaper.Tab` (a clickable tab) and
  `PhoenixPaper.TabPanel` (its content, usually written *after* the whole
  `pp_tabs/1` block, not nested inside it, same as MUI):

      <.pp_tabs id="demo-tabs">
        <.pp_tab id="demo-tabs" value="one" default_selected>One</.pp_tab>
        <.pp_tab id="demo-tabs" value="two">Two</.pp_tab>
        <.pp_tab id="demo-tabs" value="three">Three</.pp_tab>
      </.pp_tabs>

      <.pp_tab_panel id="demo-tabs" value="one" default_selected>Content one</.pp_tab_panel>
      <.pp_tab_panel id="demo-tabs" value="two">Content two</.pp_tab_panel>
      <.pp_tab_panel id="demo-tabs" value="three">Content three</.pp_tab_panel>

  Every `pp_tab/1`/`pp_tab_panel/1` in a group needs the *same* `id` as the
  `pp_tabs/1` they belong to (the same requirement, for the same reason, as
  `PhoenixPaper.Accordion`'s shared `id`) — it's how `select/2,3` below
  builds the selectors that flip everything together. Each `pp_tab/1`'s
  `value` must be unique within that group and match exactly one
  `pp_tab_panel/1`'s `value`.

  Switching tabs is handled entirely client-side with `Phoenix.LiveView.JS`
  commands (`add_class`/`remove_class`/`set_attribute`/`show`/`hide`) fired
  on click — no server round-trip, no LiveView assign to fight with on the
  next unrelated re-render, the same approach `PhoenixPaper.Dialog`/
  `PhoenixPaper.Drawer` use for their own show/hide, just extended here to
  an exclusive *N*-way choice instead of a boolean. This is also why Tabs
  isn't built the checkbox/radio-plus-`peer-checked:` way
  `PhoenixPaper.Accordion` is: `peer-checked:`/`has-*` can only express "is
  *some* sibling checked", not "which *specific* one of N siblings is
  checked" — and the panel that needs to react usually isn't even a DOM
  sibling of the tabs at all (see "CSS-only interactive state" in
  `AGENTS.md`). Mapping a selected tab to its one matching panel needs real
  per-element targeting, which only JS commands (or a full LiveView assign)
  give you.

  There's no moving/sliding indicator animation like MUI's — that requires
  measuring a specific tab's pixel offset/width at runtime, a genuine
  client-side layout query that `Phoenix.LiveView.JS` (which only issues
  fixed DOM commands, never custom computed logic) can't do without a
  bespoke JS hook. Instead the selected tab styles *itself* (colored text +
  border) — visually simpler than MUI's sliding underline, but zero custom
  JS. There's also no roving `tabindex` (MUI's `Tabs` puts only the
  selected tab in the normal Tab order, `-1` on the rest) — every tab stays
  normally focusable here, a small deviation from strict ARIA authoring
  practice traded for not needing JS to manage focus state too.

  Like `PhoenixPaper.ButtonGroup`, there's no group-level `color` that
  cascades from `Tabs` down to every `Tab` — HEEx has no mechanism for a
  parent component to reach into a child component's own assigns, so
  `color` is set per-`Tab` (keep it consistent across a group yourself).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  attr(:id, :string, required: true, doc: "shared with every Tab/TabPanel in the group")
  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))

  attr(:variant, :string,
    default: "standard",
    values: ~w(standard scrollable full_width),
    doc: "scrollable/full_width only affect orientation=\"horizontal\""
  )

  attr(:centered, :boolean,
    default: false,
    doc: "ignored for variant=\"scrollable\"/\"full_width\" or orientation=\"vertical\""
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-label aria-labelledby))

  slot(:inner_block, required: true)

  @doc "Renders a tablist container. See the module doc."
  def pp_tabs(assigns) do
    ~H"""
    <div
      role="tablist"
      aria-orientation={@orientation}
      data-pp-component="tabs"
      class={Helpers.classes(@paperize, paper_classes(@orientation, @variant, @centered), @class)}
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

  @doc false
  def active_classes("primary"), do: "border-pp-primary text-pp-primary"
  def active_classes("secondary"), do: "border-pp-secondary text-pp-secondary"
  def active_classes("tertiary"), do: "border-pp-tertiary text-pp-tertiary"
  def active_classes("error"), do: "border-pp-error text-pp-error"

  @doc false
  def inactive_classes, do: "border-transparent text-pp-on-surface"

  @all_active_classes "border-pp-primary text-pp-primary border-pp-secondary text-pp-secondary border-pp-tertiary text-pp-tertiary border-pp-error text-pp-error"

  @doc """
  A `Phoenix.LiveView.JS` command that selects the tab/panel `value` within
  the `id` group: deselects every other tab (stripping its active-indicator
  classes and `aria-selected`) and hides every other panel, then adds the
  active classes for `color` to this tab, marks it `aria-selected="true"`,
  and shows its matching panel. Wired automatically to every `pp_tab/1`'s
  own click — you don't normally call this yourself, but it's public so a
  trigger elsewhere on the page (e.g. a "next tab" button) can also switch
  tabs the same way `PhoenixPaper.Dialog.show/2` lets any button open a
  dialog.
  """
  @spec select(String.t(), String.t(), String.t()) :: JS.t()
  def select(id, value, color \\ "primary") do
    group_selector = "[data-pp-tabs-id=\"#{id}\"]"
    panel_group_selector = "[data-pp-tab-panel-group=\"#{id}\"]"

    %JS{}
    |> JS.remove_class(@all_active_classes, to: group_selector)
    |> JS.add_class(inactive_classes(), to: group_selector)
    |> JS.set_attribute({"aria-selected", "false"}, to: group_selector)
    |> JS.remove_class(inactive_classes(), to: "##{tab_id(id, value)}")
    |> JS.add_class(active_classes(color), to: "##{tab_id(id, value)}")
    |> JS.set_attribute({"aria-selected", "true"}, to: "##{tab_id(id, value)}")
    |> JS.hide(to: panel_group_selector)
    |> JS.show(to: "##{panel_id(id, value)}", display: "block")
  end

  defp paper_classes(orientation, variant, centered) do
    [
      base_classes(orientation),
      variant_classes(orientation, variant),
      centered_classes(orientation, variant, centered)
    ]
  end

  defp base_classes("horizontal"), do: "flex items-center border-b border-pp-outline"
  defp base_classes("vertical"), do: "flex flex-col items-stretch border-r border-pp-outline"

  defp variant_classes("horizontal", "scrollable"), do: "overflow-x-auto"
  defp variant_classes("horizontal", "full_width"), do: "[&>[data-pp-component=tab]]:flex-1"
  defp variant_classes(_orientation, _variant), do: ""

  defp centered_classes("horizontal", "standard", true), do: "justify-center"
  defp centered_classes(_orientation, _variant, _centered), do: ""
end
