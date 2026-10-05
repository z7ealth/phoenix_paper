defmodule PhoenixPaper.Tab do
  @moduledoc """
  A single MD3 tab (`pp_tab/1`) inside a `PhoenixPaper.Tabs` group — see
  that module for composition, variants and how selection works.

      <.pp_tab id="demo-tabs" value="photos" default_selected>
        <:icon><.pp_icon name="hero-photo" /></:icon>
        Photos
      </.pp_tab>

  `id` is the parent `pp_tabs/1`'s id; `value` is unique in the group and
  matches one `pp_tab_panel/1`. `default_selected` marks the initially
  selected tab — exactly one per group. `badge` puts a small count (or a
  dot, with `true`) next to the label.

  The tab's look reads the parent's variant through its `group/tabs`
  data attribute, so there's nothing variant-related to set here.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  import PhoenixPaper.Tabs, only: [tab_id: 2, panel_id: 2, select: 2]

  attr(:id, :string, required: true, doc: "shared with the parent Tabs and matching TabPanel")
  attr(:value, :string, required: true, doc: "unique within the group; matches a TabPanel")
  attr(:default_selected, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:badge, :any, default: nil, doc: "true for a dot, or a count")
  attr(:ripple, :boolean, default: true)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon, doc: "an optional icon — stacked above the label on primary tabs")
  slot(:inner_block, required: true)

  @doc "Renders a single tab. See the module doc."
  def pp_tab(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <button
      type="button"
      id={tab_id(@id, @value)}
      role="tab"
      aria-selected={to_string(@default_selected)}
      tabindex={if @default_selected, do: "0", else: "-1"}
      aria-controls={panel_id(@id, @value)}
      disabled={@disabled}
      data-pp-component="tab"
      data-pp-tabs-id={@id}
      class={Helpers.classes(@paperize, paper_classes(@icon != []), @class)}
      onclick={Ripple.on_click(@ripple?)}
      phx-click={select(@id, @value)}
      {@rest}
    >
      <span class={Helpers.classes(@paperize, content_classes(), nil)}>
        <span :if={@icon != []} data-pp-tab-icon class="inline-flex shrink-0">
          {render_slot(@icon)}
        </span>
        <span class="inline-flex items-center gap-1 whitespace-nowrap">
          {render_slot(@inner_block)}
          <span :if={@badge == true} class="size-1.5 rounded-full bg-pp-error" />
          <span
            :if={@badge not in [nil, false, true]}
            class="inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-pp-error px-1 pp-label-small text-pp-on-error"
          >
            {@badge}
          </span>
        </span>
        <span data-pp-tab-indicator class={Helpers.classes(@paperize, primary_indicator_classes(), nil)} />
      </span>
      <span data-pp-tab-indicator class={Helpers.classes(@paperize, secondary_indicator_classes(), nil)} />
    </button>
    """
  end

  defp paper_classes(has_icon?) do
    [
      "relative inline-flex min-w-[90px] cursor-pointer select-none items-stretch justify-center overflow-hidden px-4 pp-title-small pp-state-layer pp-focus-ring",
      "text-pp-on-surface-variant hover:text-pp-on-surface",
      "group-data-[pp-variant=primary]/tabs:aria-selected:text-pp-primary",
      "group-data-[pp-variant=secondary]/tabs:aria-selected:text-pp-on-surface",
      "disabled:pointer-events-none disabled:text-pp-on-surface/38",
      if(has_icon?, do: "h-12 group-data-[pp-variant=primary]/tabs:h-16", else: "h-12")
    ]
  end

  # The content box is the primary indicator's containing block, so that
  # indicator is exactly as wide as icon + label.
  defp content_classes do
    "relative inline-flex items-center justify-center gap-2 group-data-[pp-variant=primary]/tabs:flex-col group-data-[pp-variant=primary]/tabs:gap-0.5"
  end

  defp primary_indicator_classes do
    [
      "absolute inset-x-0.5 bottom-0 hidden h-[3px] min-w-6 rounded-t-[3px] bg-pp-primary opacity-0",
      "group-data-[pp-variant=primary]/tabs:block",
      "[[aria-selected=true]_&]:opacity-100"
    ]
  end

  defp secondary_indicator_classes do
    [
      "absolute inset-x-0 bottom-0 hidden h-0.5 bg-pp-primary opacity-0",
      "group-data-[pp-variant=secondary]/tabs:block",
      "[[aria-selected=true]>&]:opacity-100"
    ]
  end
end
