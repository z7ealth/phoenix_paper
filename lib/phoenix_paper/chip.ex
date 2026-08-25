defmodule PhoenixPaper.Chip do
  @moduledoc """
  A compact element for input, attribute, or action (`pp_chip/1`), in the
  spirit of MUI's `Chip`.

      <.pp_chip>Basic</.pp_chip>
      <.pp_chip variant="outlined" color="primary">Outlined</.pp_chip>

      <.pp_chip deletable on_delete={JS.push("remove_tag", value: %{tag: "react"})}>
        React
        <:icon><.pp_icon name="hero-check" /></:icon>
      </.pp_chip>

      <.pp_chip clickable phx-click="select_filter" phx-value-id="unread">
        Unread
      </.pp_chip>

  `clickable` (default `false`) picks the root element: a real `<button>`
  (gets native keyboard/focus/disabled handling and a `Button`-style
  ripple for free — see `PhoenixPaper.Ripple`) when `true`, a plain `<div>`
  otherwise, the same conditional-root-tag approach `PhoenixPaper.ListItem`
  uses for link-vs-static (see AGENTS.md) — HEEx can't parameterize a tag
  name, so this is two `:if`/`:if={!...}` branches sharing one private
  `chip_content/1` for the icon/label/delete markup. Pass `phx-click`
  through `rest` (like `PhoenixPaper.ToggleButton`) for the click itself;
  `clickable={false}` (the default) with `deletable={true}` is exactly
  MUI's "chip with a delete affordance but no other interaction" case — a
  static tag the caller can still remove.

  The delete "button" (only rendered when `deletable` is `true`) is
  deliberately a `<span role="button" tabindex="0">`, not a real `<button>`
  — a real `<button>` nested inside `clickable`'s own `<button>` root would
  be invalid HTML (browsers auto-close the outer one, breaking the whole
  chip's layout). A small `onkeydown` snippet (Enter/Space triggers a
  synthetic click, same "small vanilla snippet, no hook" precedent as
  `PhoenixPaper.Ripple`) keeps it keyboard-operable despite not being a real
  button, and its `onclick` calls `event.stopPropagation()` so clicking
  delete on a `clickable` chip doesn't also fire the chip's own click.

  `disabled` dims and disables **both** the root (when `clickable`, a real
  `disabled` attribute; when not, `pointer-events-none` — a plain `<div>`
  has no native `disabled`) and the delete control (`pointer-events-none`
  plus `tabindex="-1"`, removing it from the tab order) — it isn't gated
  behind `clickable` since `deletable`-only chips (no other interaction)
  can still need to be disabled.

  `color="default"` (gray, using `--color-pp-surface-variant`/
  `-on-surface`/`-outline` — the same neutral tokens `Input`/`Select`/
  `NumberField` already use for their filled backgrounds) is the default
  here, unlike every other colored component in this library — a plain tag
  chip (MUI's most common real-world case) is neutral, not brand-colored.
  Every other `color` value (`primary`/`secondary`/`tertiary`/`error`, plus
  `success`/`warning`/`info` for status, see `PhoenixPaper.Alert`) is also
  available.

  `clickable`'s hover/active feedback is one `filter: brightness()` step
  (`hover:brightness-95 active:brightness-90`) applied uniformly across
  every `color`/`variant` combination, rather than a hand-picked
  color-matched tint per branch the way `PhoenixPaper.Button`'s `outlined`/
  `text` variants do (`hover:bg-pp-primary/10`, etc.) — simpler, and the
  one place a chip's hover feedback is a little more subtle for an
  `outlined`/transparent-background chip than for a `filled` one, since a
  brightness filter has less visible effect over a transparent background.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  @keydown_activate "if(event.key==='Enter'||event.key===' '){event.preventDefault();event.currentTarget.click();}"

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "filled", values: ~w(filled outlined))

  attr(:color, :string,
    default: "default",
    values: ~w(default primary secondary tertiary error success warning info)
  )

  attr(:size, :string, default: "medium", values: ~w(small medium))

  attr(:clickable, :boolean,
    default: false,
    doc: "renders as a real <button> with hover/focus/ripple, for filter/action chips"
  )

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap when clickable — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))

  attr(:deletable, :boolean,
    default: false,
    doc: "renders a trailing delete (x) control wired to on_delete"
  )

  attr(:on_delete, JS,
    default: %JS{},
    doc: ~s[JS command run when the delete control is clicked, e.g. JS.push("remove_chip")]
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value phx-click))

  slot(:icon, doc: "a leading icon or avatar")
  slot(:inner_block, required: true, doc: "the chip's label")

  @doc "Renders a chip. See the module doc."
  def pp_chip(assigns) do
    assigns = assign(assigns, :ripple?, assigns.clickable and assigns.ripple and assigns.paperize)

    ~H"""
    <button
      :if={@clickable}
      type={@type}
      disabled={@disabled}
      data-pp-component="chip"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @color, @size, true, @disabled, @ripple?), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {chip_content(assigns)}
    </button>
    <div
      :if={!@clickable}
      data-pp-component="chip"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @color, @size, false, @disabled, false), @class)}
      {@rest}
    >
      {chip_content(assigns)}
    </div>
    """
  end

  defp chip_content(assigns) do
    ~H"""
    <span :if={@icon != []} class={icon_slot_classes(@size)}>{render_slot(@icon)}</span>
    <span class="truncate">{render_slot(@inner_block)}</span>
    <span
      :if={@deletable}
      role="button"
      tabindex={if @disabled, do: "-1", else: "0"}
      aria-label="Remove"
      aria-disabled={to_string(@disabled)}
      data-pp-component="chip-delete"
      class={Helpers.classes(@paperize, delete_classes(@size, @disabled), nil)}
      onclick="event.stopPropagation();"
      onkeydown={keydown_activate_script()}
      phx-click={@on_delete}
    >
      <.pp_icon name="hero-x-mark-mini" class={icon_size_classes(@size)} />
    </span>
    """
  end

  defp paper_classes(variant, color, size, clickable, disabled, ripple) do
    [
      "inline-flex items-center gap-1.5 rounded-full font-medium select-none transition-colors",
      size_classes(size),
      color_classes(variant, color),
      clickable_classes(clickable),
      disabled_classes(disabled),
      Ripple.container_classes(ripple)
    ]
  end

  defp size_classes("small"), do: "h-6 px-2.5 text-xs"
  defp size_classes("medium"), do: "h-8 px-3 text-sm"

  defp icon_slot_classes("small"), do: "flex shrink-0 items-center [&>*]:size-3.5"
  defp icon_slot_classes("medium"), do: "flex shrink-0 items-center [&>*]:size-4"

  defp icon_size_classes("small"), do: "!size-3.5"
  defp icon_size_classes("medium"), do: "!size-4"

  defp keydown_activate_script, do: @keydown_activate

  defp clickable_classes(false), do: ""

  defp clickable_classes(true),
    do:
      "cursor-pointer hover:brightness-95 active:brightness-90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"

  defp disabled_classes(false), do: ""
  defp disabled_classes(true), do: "pointer-events-none opacity-40"

  defp delete_classes(size, disabled) do
    [
      "inline-flex shrink-0 cursor-pointer items-center justify-center rounded-full opacity-70 transition-opacity hover:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1",
      icon_size_classes(size),
      if(disabled, do: "pointer-events-none", else: "")
    ]
  end

  defp color_classes("filled", "default"), do: "bg-pp-surface-variant text-pp-on-surface"
  defp color_classes("filled", "primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("filled", "secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("filled", "tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("filled", "error"), do: "bg-pp-error text-pp-on-error"
  defp color_classes("filled", "success"), do: "bg-pp-success text-pp-on-success"
  defp color_classes("filled", "warning"), do: "bg-pp-warning text-pp-on-warning"
  defp color_classes("filled", "info"), do: "bg-pp-info text-pp-on-info"

  defp color_classes("outlined", "default"),
    do: "bg-transparent text-pp-on-surface border border-pp-outline"

  defp color_classes("outlined", "primary"),
    do: "bg-transparent text-pp-primary border border-pp-primary"

  defp color_classes("outlined", "secondary"),
    do: "bg-transparent text-pp-secondary border border-pp-secondary"

  defp color_classes("outlined", "tertiary"),
    do: "bg-transparent text-pp-tertiary border border-pp-tertiary"

  defp color_classes("outlined", "error"),
    do: "bg-transparent text-pp-error border border-pp-error"

  defp color_classes("outlined", "success"),
    do: "bg-transparent text-pp-success border border-pp-success"

  defp color_classes("outlined", "warning"),
    do: "bg-transparent text-pp-warning border border-pp-warning"

  defp color_classes("outlined", "info"),
    do: "bg-transparent text-pp-info border border-pp-info"
end
