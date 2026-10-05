defmodule PhoenixPaper.Tooltip do
  @moduledoc """
  MD3 tooltips (`pp_tooltip/1`) — plain and rich — shown on hover and
  keyboard focus.

      <.pp_tooltip title="Delete">
        <.pp_icon_button icon="hero-trash" label="Delete" title={false} />
      </.pp_tooltip>

      <.pp_tooltip variant="rich" subhead="Autosave" title="Changes are saved as you type.">
        <.pp_icon_button icon="hero-information-circle" label="About autosave" title={false} />
        <:actions><.pp_button variant="text" size="xs" navigate={~p"/help/autosave"}>Learn more</.pp_button></:actions>
      </.pp_tooltip>

  ## Variants

  - `plain` (default): a short label — `inverse-surface` chip,
    `body-small` text, 4dp corners, wrapping at 200px. Not interactive.
  - `rich`: a small card — `surface-container` with a level-2 shadow and
    12dp corners, an optional `subhead` (`title-small`), the `title` as
    supporting text (`body-medium`, `on-surface-variant`) and optional
    `:actions` (text buttons). It stays open while hovered, so its actions
    are clickable: the gap between trigger and bubble is padding inside
    the hover target, not margin.

  ## Behavior

  Pure CSS: the wrapper is a named `group/tooltip` (so an outer `group`
  can't trigger it), and the bubble shows on `group-hover/tooltip:` and
  `group-focus-within/tooltip:` — so keyboard users get it too.
  Showing waits a beat (MD3's hover delay, `delay-300`); hiding is
  immediate. `title={nil}`/`""` renders just the trigger.

  `placement` is `top` (default), `bottom`, `left` or `right`. With the
  optional JS hook and an `id` on the tooltip, it **flips** to the
  opposite side when it would overflow the viewport (measured as it
  shows); without the hook the placement is fixed.

  Give an icon button inside `title={false}` so it doesn't show its own
  native tooltip too.

  The wrapper's `group/tooltip relative inline-flex` is structural and
  stays on under `paperize={false}`; the bubble's classes are gated as usual.

  ## Migrating from 0.3

  `color`, `size`, `shape`, `arrow` and the `raised`/`flat`/`outlined`
  variants are gone: MD3 tooltips have one look per variant, and no arrow.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:title, :any,
    default: nil,
    doc: "the tooltip text (rich: supporting text) — nil or \"\" disables it"
  )

  attr(:variant, :string, default: "plain", values: ~w(plain rich))
  attr(:subhead, :string, default: nil, doc: "rich tooltips: a title above the text")
  attr(:placement, :string, default: "top", values: ~w(top bottom left right))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the trigger element")
  slot(:actions, doc: "rich tooltips: text buttons under the text")

  @doc "Renders a tooltip. See the module doc."
  def pp_tooltip(assigns) do
    ~H"""
    <span
      data-pp-component="tooltip"
      phx-hook={Helpers.hook(@rest[:id])}
      class="group/tooltip relative inline-flex"
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        :if={@title not in [nil, ""]}
        role="tooltip"
        data-pp-component="tooltip-bubble"
        data-pp-variant={@variant}
        data-pp-placement={@placement}
        class={Helpers.classes(@paperize, reveal_classes(@variant, @placement), nil)}
      >
        <span class={Helpers.classes(@paperize, bubble_classes(@variant), @class)}>
          <span :if={@variant == "rich" && @subhead} class="block pp-title-small text-pp-on-surface">
            {@subhead}
          </span>
          {@title}
          <span :if={@variant == "rich" && @actions != []} class="-ms-3 mt-2 flex gap-2">
            {render_slot(@actions)}
          </span>
        </span>
      </span>
    </span>
    """
  end

  # The positioned, revealable wrapper. Its padding (not margin) is the gap
  # to the trigger, so for a rich tooltip the pointer never leaves the
  # group crossing it.
  defp reveal_classes(variant, placement) do
    [
      "absolute z-30 invisible opacity-0 transition-[opacity,visibility] duration-150 ease-pp-standard",
      "group-hover/tooltip:visible group-hover/tooltip:opacity-100 group-hover/tooltip:delay-300",
      "group-focus-within/tooltip:visible group-focus-within/tooltip:opacity-100",
      if(variant == "rich", do: "pointer-events-auto", else: "pointer-events-none"),
      placement_classes(placement)
    ]
  end

  defp placement_classes("top"), do: "bottom-full left-1/2 -translate-x-1/2 pb-1"
  defp placement_classes("bottom"), do: "top-full left-1/2 -translate-x-1/2 pt-1"
  defp placement_classes("left"), do: "right-full top-1/2 -translate-y-1/2 pe-1"
  defp placement_classes("right"), do: "left-full top-1/2 -translate-y-1/2 ps-1"

  defp bubble_classes("plain"),
    do:
      "block w-max max-w-[200px] rounded-pp-xs bg-pp-inverse-surface px-2 py-1 pp-body-small text-pp-inverse-on-surface"

  defp bubble_classes("rich"),
    do:
      "block w-max max-w-[312px] rounded-pp-md bg-pp-surface-container px-4 pb-2 pt-3 pp-body-medium text-pp-on-surface-variant pp-elevation-2"
end
