defmodule PhoenixPaper.Chip do
  @moduledoc """
  MD3 chips (`pp_chip/1`): assist, filter, input and suggestion.

      <%!-- assist: a smart action, with a leading icon --%>
      <.pp_chip variant="assist" phx-click="add_to_calendar">
        <:icon><.pp_icon name="hero-calendar" /></:icon>
        Add to calendar
      </.pp_chip>

      <%!-- filter: toggles; a check appears when selected --%>
      <.pp_chip variant="filter" toggle selected={false} on_toggle={JS.push("filter", value: %{f: "unread"})}>
        Unread
      </.pp_chip>

      <%!-- input: a user-entered value, removable --%>
      <.pp_chip variant="input" deletable on_delete={JS.push("remove_tag", value: %{tag: "elixir"})}>
        elixir
      </.pp_chip>

      <%!-- suggestion: a dynamically generated reply/query --%>
      <.pp_chip variant="suggestion" phx-click="reply" phx-value-text="Sounds good">Sounds good</.pp_chip>

  All chips are 32dp tall with 8dp corners and `label-large` text, on an
  `outline-variant` outline; `elevated` swaps the outline for a
  `surface-container-low` fill and a level-1 shadow (assist, filter and
  suggestion chips; MD3 uses it on busy backgrounds).

  ## Kinds

  - `assist` (default): a `<button>`; its leading `:icon` is `primary`.
  - `filter`: a toggle `<button>` — `selected` plus the
    `toggle`/`group`/`on_toggle` attrs `PhoenixPaper.Button` uses (see
    `PhoenixPaper.Toggle`), so a set of filter chips can be multi-select
    (`toggle`) or single-select (`group="sort"`), client-side or controlled
    by the server. Selected chips turn `secondary-container` and show a
    leading check.
  - `input`: a `<div>` (or a `<button>` with `clickable`) for a value the
    user entered; `deletable` adds the trailing remove control running
    `on_delete`. `selected` gives it the selected color.
  - `suggestion`: a `<button>` like `assist`, without the colored icon.

  ## The remove control

  It's a `<span role="button" tabindex="0">`, not a `<button>`: a button
  nested in a clickable chip's `<button>` is invalid HTML. A small
  `onkeydown` snippet makes Enter/Space click it. It doesn't stop
  propagation — LiveView resolves a click to the nearest `phx-click`, so
  the remove control's own binding wins over the chip's.

  ## Migrating from 0.3

  `variant` `filled`/`outlined` → the four kinds (`outlined` look is the
  default; `elevated` for a fill), `clickable` now only matters for input
  chips, `color` and `size` are gone (MD3 chips have one color scheme and
  one size), `deletable`/`on_delete` stay.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Ripple, Toggle}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  @keydown_activate "if(event.key==='Enter'||event.key===' '){event.preventDefault();event.currentTarget.click();}"

  attr(:paperize, :boolean, default: true)
  attr(:variant, :string, default: "assist", values: ~w(assist filter input suggestion))
  attr(:elevated, :boolean, default: false, doc: "fill + shadow instead of the outline")

  attr(:selected, :boolean,
    default: nil,
    doc: "filter/input chips: the (initial) selected state"
  )

  attr(:toggle, :boolean, default: false, doc: "filter chips: toggle on the client")
  attr(:group, :string, default: nil, doc: "filter chips: single-select group name")
  attr(:on_toggle, JS, default: %JS{}, doc: "filter chips: JS run after a client toggle")

  attr(:clickable, :boolean,
    default: false,
    doc: "input chips: render a <button> instead of a static <div>"
  )

  attr(:ripple, :boolean, default: true)
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:deletable, :boolean, default: false, doc: "trailing remove control (input chips)")

  attr(:on_delete, JS,
    default: %JS{},
    doc: ~s[JS run by the remove control, e.g. JS.push("remove_chip")]
  )

  attr(:delete_label, :string, default: "Remove")
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value))

  slot(:icon, doc: "a leading icon or avatar")
  slot(:inner_block, required: true, doc: "the chip's label")

  @doc "Renders a chip. See the module doc."
  def pp_chip(assigns) do
    button? = assigns.variant != "input" or assigns.clickable
    filter? = assigns.variant == "filter"
    client_toggle? = filter? and (assigns.toggle or assigns.group != nil)

    assigns =
      assigns
      |> assign(:button?, button?)
      |> assign(:filter?, filter?)
      |> assign(:client_toggle?, client_toggle?)
      |> assign(
        :ripple?,
        button? and assigns.ripple and assigns.paperize and not assigns.disabled
      )

    ~H"""
    <button
      :if={@button?}
      type={@type}
      disabled={@disabled}
      aria-pressed={@filter? && Toggle.aria_pressed(@selected, true)}
      data-pp-component="chip"
      data-pp-variant={@variant}
      data-pp-toggle-group={@filter? && @group}
      class={Helpers.classes(@paperize, paper_classes(assigns, true), @class)}
      onclick={Ripple.on_click(@ripple?)}
      phx-click={@client_toggle? && Toggle.js(@group, @on_toggle)}
      {@rest}
    >
      {chip_content(assigns)}
    </button>
    <div
      :if={!@button?}
      data-pp-component="chip"
      data-pp-variant={@variant}
      aria-disabled={@disabled && "true"}
      class={Helpers.classes(@paperize, paper_classes(assigns, false), @class)}
      {@rest}
    >
      {chip_content(assigns)}
    </div>
    """
  end

  defp chip_content(assigns) do
    ~H"""
    <.pp_icon
      :if={@filter?}
      name="hero-check"
      size="sm"
      class="-ms-2 shrink-0 [[aria-pressed=false]>&]:hidden"
    />
    <span :if={@icon != []} class={icon_slot_classes(@variant)}>{render_slot(@icon)}</span>
    <span class="truncate">{render_slot(@inner_block)}</span>
    <span
      :if={@deletable}
      role="button"
      tabindex={if @disabled, do: "-1", else: "0"}
      aria-label={@delete_label}
      aria-disabled={to_string(@disabled)}
      data-pp-component="chip-delete"
      class={Helpers.classes(@paperize, delete_classes(@disabled), nil)}
      onkeydown={keydown_activate_script()}
      phx-click={@on_delete}
    >
      <.pp_icon name="hero-x-mark" size="none" class="size-[18px]" />
    </span>
    """
  end

  defp paper_classes(assigns, interactive?) do
    [
      "relative inline-flex h-8 max-w-full items-center gap-2 overflow-hidden rounded-pp-sm px-4 pp-label-large select-none pp-motion-effects-fast",
      (assigns.icon != [] or assigns.filter?) && "ps-2",
      assigns.deletable && "pe-2",
      surface_classes(assigns.variant, assigns.elevated, assigns.selected),
      interactive? && "cursor-pointer pp-state-layer pp-focus-ring",
      "disabled:pointer-events-none disabled:border-pp-on-surface/12 disabled:text-pp-on-surface/38 aria-disabled:pointer-events-none aria-disabled:border-pp-on-surface/12 aria-disabled:text-pp-on-surface/38"
    ]
  end

  # Filter chips style the selected state off aria-pressed (it may flip on
  # the client); input chips off the server's `selected`.
  defp surface_classes("filter", false, _selected),
    do:
      "border border-pp-outline-variant text-pp-on-surface-variant aria-pressed:border-transparent aria-pressed:bg-pp-secondary-container aria-pressed:text-pp-on-secondary-container"

  defp surface_classes("filter", true, _selected),
    do:
      "bg-pp-surface-container-low text-pp-on-surface-variant pp-elevation-1 aria-pressed:bg-pp-secondary-container aria-pressed:text-pp-on-secondary-container"

  defp surface_classes("input", _elevated, true),
    do: "bg-pp-secondary-container text-pp-on-secondary-container"

  defp surface_classes("input", _elevated, _selected),
    do: "border border-pp-outline-variant text-pp-on-surface-variant"

  defp surface_classes("assist", false, _selected),
    do: "border border-pp-outline-variant text-pp-on-surface"

  defp surface_classes("assist", true, _selected),
    do: "bg-pp-surface-container-low text-pp-on-surface pp-elevation-1"

  defp surface_classes("suggestion", false, _selected),
    do: "border border-pp-outline-variant text-pp-on-surface-variant"

  defp surface_classes("suggestion", true, _selected),
    do: "bg-pp-surface-container-low text-pp-on-surface-variant pp-elevation-1"

  defp icon_slot_classes("assist"),
    do: "flex shrink-0 items-center text-pp-primary [&>*]:size-[18px]"

  defp icon_slot_classes(_variant), do: "flex shrink-0 items-center [&>*]:size-[18px]"

  defp keydown_activate_script, do: @keydown_activate

  defp delete_classes(disabled) do
    [
      "relative z-10 inline-flex size-6 shrink-0 cursor-pointer items-center justify-center rounded-pp-full pp-state-layer pp-focus-ring",
      disabled && "pointer-events-none"
    ]
  end
end
