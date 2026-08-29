defmodule PhoenixPaper.Flash do
  @moduledoc """
  Renders Phoenix's flash messages (`@flash`) as `PhoenixPaper.Snackbar`s
  (`pp_flash_group/1`) — the Material equivalent of the `flash_group/1` in
  a freshly generated `core_components.ex`.

      <.pp_flash_group flash={@flash} />

  Drop it once in your root layout (or app layout), the same place the
  generated `<.flash_group>` goes. It reads `:info` and `:error` out of
  the flash and shows one inverted-surface chip per present message,
  stacked at a corner of the viewport:

  - **Dismiss** is wired to LiveView's built-in `lv:clear-flash` client
    event (`Phoenix.LiveView.JS.push("lv:clear-flash", value: %{key: kind})`)
    — no handler in your LiveView, no `put_flash`/`clear_flash` round trip
    to write. Clicking the chip's ✕ clears that key; the server re-renders
    without it and the chip is gone.
  - **Auto-dismiss** is opt-in: `auto_hide_duration={4000}` makes each chip
    clear itself after 4s via the same `lv:clear-flash`, using
    `PhoenixPaper.Snackbar`'s hook-free CSS-animation timer. Left off, the
    chips stay until dismissed (or replaced by the next navigation, as
    Phoenix flash already does).

  ## Why a wrapper and not just "use `pp_snackbar`"

  `pp_snackbar` is presentation-only and positions itself. A *group* of
  flash messages needs (a) to read the flash map, (b) to key each chip's
  dismiss to the right flash key, and (c) to stack several without them
  landing on top of each other — none of which a single self-positioning
  toast should own. `pp_flash_group` owns the `fixed` corner stack;
  each chip inside is a `pp_snackbar positioned={false}`.

  ## Kinds beyond `:info`/`:error`

  Pass `kinds` to change or extend the list (`kinds={[:info, :warning, :error]}`).
  Each kind gets a leading icon (`info`/`warning`/`error`/`success` are
  recognised; anything else renders with no icon). Material snackbars are
  monochrome by spec — the inverted chip is the same for every kind, the
  icon carries the distinction — so there's deliberately no per-kind
  background colour here (use `PhoenixPaper.Alert` inside a bare
  `pp_snackbar` if you want coloured severity surfaces).

  The `:client-error` / `:server-error` connection-lost flashes that
  `core_components.ex` renders with `phx-disconnected` are a different
  mechanism (no server flash entry backs them) and aren't handled here —
  keep the generated `<.flash>` for those, or add your own.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PhoenixPaper.Snackbar, only: [pp_snackbar: 1]
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  @anchor_values ~w(bottom-left bottom-center bottom-right top-left top-center top-right)

  attr(:flash, :map, required: true, doc: "the @flash map from the assigns")

  attr(:kinds, :list,
    default: [:info, :error],
    doc: "flash keys to render, in stacking order"
  )

  attr(:anchor_origin, :string,
    default: "bottom-right",
    values: @anchor_values,
    doc: "corner/edge of the viewport the stack sits at"
  )

  attr(:auto_hide_duration, :integer,
    default: nil,
    doc: "milliseconds after which each chip clears itself via lv:clear-flash (opt-in)"
  )

  attr(:transition, :string, default: "slide", values: ~w(grow fade slide none))
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders every present flash message as a stacked snackbar. See the module doc."
  def pp_flash_group(assigns) do
    ~H"""
    <div
      data-pp-component="flash-group"
      class={[@paperize && stack_classes(@anchor_origin), @class]}
      {@rest}
    >
      <.pp_flash
        :for={kind <- @kinds}
        kind={kind}
        flash={@flash}
        anchor_origin={@anchor_origin}
        auto_hide_duration={@auto_hide_duration}
        transition={@transition}
        paperize={@paperize}
      />
    </div>
    """
  end

  attr(:kind, :atom, required: true)
  attr(:flash, :map, required: true)
  attr(:anchor_origin, :string, default: "bottom-right", values: @anchor_values)
  attr(:auto_hide_duration, :integer, default: nil)
  attr(:transition, :string, default: "slide")
  attr(:paperize, :boolean, default: true)

  @doc "Renders one flash key as a snackbar, or nothing when that key is empty."
  def pp_flash(assigns) do
    assigns = assign(assigns, :message, Phoenix.Flash.get(assigns.flash, assigns.kind))

    ~H"""
    <.pp_snackbar
      :if={@message}
      id={"pp-flash-#{@kind}"}
      role={if @kind == :error, do: "alert", else: "status"}
      positioned={false}
      anchor_origin={@anchor_origin}
      transition={@transition}
      auto_hide_duration={@auto_hide_duration}
      on_close={JS.push("lv:clear-flash", value: %{key: to_string(@kind)})}
      paperize={@paperize}
    >
      <span class="flex items-center gap-3">
        <.pp_icon :if={icon_name(@kind)} name={icon_name(@kind)} class="!size-5 shrink-0" />
        <span>{@message}</span>
      </span>
    </.pp_snackbar>
    """
  end

  defp icon_name(:info), do: "hero-information-circle-mini"
  defp icon_name(:success), do: "hero-check-circle-mini"
  defp icon_name(:warning), do: "hero-exclamation-triangle-mini"
  defp icon_name(:error), do: "hero-exclamation-circle-mini"
  defp icon_name(_), do: nil

  defp stack_classes(anchor_origin) do
    [
      "pointer-events-none fixed z-50 flex flex-col gap-2 [&_[data-pp-component=snackbar]]:pointer-events-auto",
      corner_classes(anchor_origin)
    ]
  end

  defp corner_classes("bottom-left"),
    do: "inset-x-4 bottom-4 items-start sm:inset-x-auto sm:left-4"

  defp corner_classes("bottom-center"),
    do: "inset-x-4 bottom-4 items-center sm:inset-x-auto sm:left-1/2 sm:-translate-x-1/2"

  defp corner_classes("bottom-right"),
    do: "inset-x-4 bottom-4 items-end sm:inset-x-auto sm:right-4"

  defp corner_classes("top-left"),
    do: "inset-x-4 top-4 items-start sm:inset-x-auto sm:left-4"

  defp corner_classes("top-center"),
    do: "inset-x-4 top-4 items-center sm:inset-x-auto sm:left-1/2 sm:-translate-x-1/2"

  defp corner_classes("top-right"), do: "inset-x-4 top-4 items-end sm:inset-x-auto sm:right-4"
end
