defmodule PhoenixPaper.Tab do
  @moduledoc """
  A single clickable tab (`pp_tab/1`) inside a `PhoenixPaper.Tabs` tablist,
  paired with a `PhoenixPaper.TabPanel` sharing the same `id`/`value`. See
  `PhoenixPaper.Tabs`'s moduledoc for the full composition example and for
  why switching is JS-command-driven rather than the CSS-only
  `peer-checked:` trick `PhoenixPaper.Accordion` uses.

  `id` must be the same on every `Tab`/`TabPanel` in the group; `value`
  must be unique within it. `orientation` must match the parent
  `pp_tabs/1`'s own `orientation` — like `color`, it can't cascade down
  automatically (see `PhoenixPaper.Tabs`'s moduledoc), it only changes
  which side the persistent 2px indicator border reserves space on.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  import PhoenixPaper.Tabs,
    only: [tab_id: 2, panel_id: 2, active_classes: 1, inactive_classes: 0, select: 3]

  attr(:id, :string, required: true, doc: "shared with the parent Tabs and matching TabPanel")

  attr(:value, :string,
    required: true,
    doc: "unique within the group; matches a TabPanel's value"
  )

  attr(:orientation, :string, default: "horizontal", values: ~w(horizontal vertical))
  attr(:default_selected, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary error))

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:icon, doc: "optional leading icon, e.g. a <.pp_icon>")
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
      aria-controls={panel_id(@id, @value)}
      disabled={@disabled}
      data-pp-component="tab"
      data-pp-tabs-id={@id}
      class={Helpers.classes(@paperize, paper_classes(@orientation, @default_selected, @color, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      phx-click={select(@id, @value, @color)}
      {@rest}
    >
      <span :if={@icon != []} class="shrink-0">{render_slot(@icon)}</span>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp paper_classes(orientation, default_selected, color, ripple) do
    [
      base_classes(orientation),
      selection_classes(default_selected, color),
      Ripple.container_classes(ripple)
    ]
  end

  defp base_classes("horizontal"),
    do:
      "inline-flex items-center justify-center gap-2 border-b-2 px-4 py-3 text-sm font-medium cursor-pointer select-none transition-colors disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 hover:bg-pp-on-surface/5"

  defp base_classes("vertical"),
    do:
      "flex w-full items-center justify-start gap-2 border-r-2 px-4 py-3 text-sm font-medium cursor-pointer select-none transition-colors disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 hover:bg-pp-on-surface/5"

  defp selection_classes(true, color), do: active_classes(color)
  defp selection_classes(false, _color), do: inactive_classes()
end
