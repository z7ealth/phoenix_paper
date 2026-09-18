defmodule PhoenixPaper.Snackbar do
  @moduledoc """
  A brief toast notification (`pp_snackbar/1`), in the spirit of MUI's
  `Snackbar`.

      <.pp_snackbar open={@flash_message != nil}>
        {@flash_message}
        <:action>
          <.pp_button variant="text" phx-click="dismiss_flash">Dismiss</.pp_button>
        </:action>
      </.pp_snackbar>

  Positioning (`anchor_origin`), the dark inverted-surface chip, a mount-in
  `transition`, an optional `:action` slot, an optional `on_close` dismiss
  button, and an optional `auto_hide_duration`. For rendering Phoenix flash
  messages as snackbars, reach for `PhoenixPaper.Flash.pp_flash_group/1`,
  which wraps this component. A few things MUI's `Snackbar` has that this
  doesn't, and why:

  - **`autoHideDuration` is opt-in and client-only.** Set
    `auto_hide_duration` (milliseconds) *together with* `on_close` and the
    snackbar dismisses itself after that delay by triggering `on_close` —
    implemented with a CSS animation whose `animationend` clicks the close
    button, no JS hook (the same "small vanilla snippet" philosophy as
    `PhoenixPaper.Ripple`). The same animation also **doubles as a visible
    countdown**: a thin bar along the chip's bottom edge shrinks from full
    width to nothing over exactly `auto_hide_duration`, so the timing that
    drives the dismissal is the same timing the user can see — there's no
    separate "fake" progress indicator to keep in sync with the real timer
    (an earlier version animated an invisible, zero-footprint `opacity: 1 →
    1` span purely for its `animationend` timing hook; the bar is the same
    span, now actually painted). Under `paperize={false}` it goes back to
    invisible-but-functional — only the animation/timing classes stay
    unconditional, the bar's size/color are stripped like every other
    built-in visual, so `auto_hide_duration` still works with nothing left
    to render it. Off by default because the server is usually the better
    owner of "is this message still live" — one `Process.send_after/3`
    clearing whatever assign controls `open`, the mechanism `mix phx.new`'s
    generated flash already uses. Use the client timer when there's no
    server round-trip to hang it off (a purely client-dismissed flash via
    `JS.push("lv:clear-flash")`).
  - **No exit transition.** `open={false}` removes the element from the DOM
    immediately (`:if` under the hood) — animating *that* would need the
    same always-rendered-plus-`Phoenix.LiveView.JS` machinery
    `PhoenixPaper.Dialog` uses, which is a much bigger component for a
    toast. `transition` only animates the *entrance* (a real CSS
    `@keyframes` animation that plays once when the element mounts), which
    covers the common case — a snackbar popping in — without needing that
    machinery.
  - **No built-in queueing** of consecutive snackbars (MUI shows them one at
    a time, queued). That needs a place to actually hold the queue — a
    LiveComponent or a list in your LiveView's own assigns — not something
    a stateless function component can own. Render one `pp_snackbar` for
    whatever message you're currently showing; queuing which message that
    is is your call, the same as it would be building this by hand.
  - **No dedicated "wrap an Alert" mode** — MUI's `Snackbar` skips its own
    background/padding when given a child instead of `message`/`action`, so
    an `Alert` inside shows only the Alert's own colors. Here, pass
    `paperize={false}` (drops the inverted-surface chip *and* the
    positioning classes together, this library's usual all-or-nothing
    contract) and supply both back yourself via `class`:

        <.pp_snackbar paperize={false} class="fixed inset-x-4 bottom-4 z-50 mx-auto w-fit">
          <.pp_alert severity="success">Changes saved.</.pp_alert>
        </.pp_snackbar>

    If you only need to move the chip (keep its styling, drop the
    viewport anchoring — e.g. to stack several inside your own container),
    use `positioned={false}` instead of going fully `paperize={false}`.

  ## `color`

  Defaults to `"default"` — the inverted `bg-pp-on-surface`/`text-pp-surface`
  chip described below, unchanged from before this attr existed. Material's
  own spec keeps a snackbar monochrome regardless of severity/kind (see
  `PhoenixPaper.Flash`'s moduledoc, which relies on exactly that to stay
  colorless across `:info`/`:warning`/`:error`) — `color` is a deliberate
  departure from that spec for callers who *do* want a brand-colored toast
  (`"primary"`/`"secondary"`/`"accent"`/`"error"`, the same brand scale
  `PhoenixPaper.Button` uses), the same way `PhoenixPaper.Drawer`'s `color`
  is an opt-in departure from its own original neutral-only look. The close
  button and the `auto_hide_duration` timer bar (below) both switch their
  own contrast to match whichever surface is picked, the same
  `text-pp-on-<color>`-reaching pattern `Drawer`'s colored variants use for
  their nested content.

  Always uses `bg-pp-on-surface`/`text-pp-surface` when `color="default"`
  (unchanged) — an *inverted* surface (dark chip on a light theme, light
  chip on a dark theme) is the Material spec for a snackbar, not a themed
  surface like `PhoenixPaper.Paper`. Picking a brand `color` trades that
  spec-correct inversion for a colored surface instead — a deliberate
  opt-in, not the default.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Elevation, Helpers}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:open, :boolean, default: true)

  attr(:color, :string,
    default: "default",
    values: ~w(default primary secondary accent error),
    doc: "default is the inverted monochrome Material spec; the others paint a brand-colored chip"
  )

  attr(:anchor_origin, :string,
    default: "bottom-left",
    values: ~w(bottom-left bottom-center bottom-right top-left top-center top-right),
    doc: "corner/edge of the viewport it's anchored to"
  )

  attr(:transition, :string,
    default: "grow",
    values: ~w(grow fade slide none),
    doc: "the mount-in animation — there's no exit transition, see the module doc"
  )

  attr(:positioned, :boolean,
    default: true,
    doc:
      "keep the viewport-anchored `fixed` positioning — set false to drop it and place the chip yourself (e.g. inside PhoenixPaper.Flash's stack)"
  )

  attr(:elevation, :integer, default: 6)

  attr(:on_close, JS,
    default: nil,
    doc: "when set, renders a trailing ✕ button running this — MUI's close-IconButton pattern"
  )

  attr(:auto_hide_duration, :integer,
    default: nil,
    doc:
      "milliseconds after which the snackbar triggers on_close itself (client-side; needs on_close set)"
  )

  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:action)
  slot(:inner_block, required: true)

  @doc "Renders a snackbar. See the module doc."
  def pp_snackbar(assigns) do
    ~H"""
    <div
      :if={@open}
      role="status"
      data-pp-component="snackbar"
      data-pp-anchor-origin={@anchor_origin}
      class={
        Helpers.classes(
          @paperize,
          paper_classes(@color, @anchor_origin, @transition, @elevation, @positioned),
          @class
        )
      }
      {@rest}
    >
      <div class="text-sm">{render_slot(@inner_block)}</div>
      <div :if={@action != []} class="flex shrink-0 items-center">{render_slot(@action)}</div>
      <button
        :if={@on_close}
        type="button"
        data-pp-snackbar-close
        phx-click={@on_close}
        aria-label="Close"
        class={
          Helpers.classes(
            @paperize,
            ["-mr-1 inline-flex size-8 shrink-0 cursor-pointer items-center justify-center rounded-full transition-colors", close_button_classes(@color)],
            nil
          )
        }
      >
        <.pp_icon name="hero-x-mark-mini" class="!size-4" />
      </button>
      <span
        :if={@on_close && @auto_hide_duration}
        aria-hidden="true"
        class={[
          "pp-snackbar-timeout pointer-events-none absolute",
          Helpers.classes(@paperize, ["inset-x-0 bottom-0 h-1", timer_bar_classes(@color)], nil)
        ]}
        style={"--pp-snackbar-timeout: #{@auto_hide_duration}ms"}
        onanimationend="var b=this.parentNode.querySelector('[data-pp-snackbar-close]');if(b){b.click()}"
      />
    </div>
    """
  end

  defp paper_classes(color, anchor_origin, transition, elevation, positioned) do
    [
      "relative z-50 mx-auto flex w-fit max-w-md items-center gap-4 overflow-hidden rounded-lg px-4 py-3",
      surface_classes(color),
      if(positioned, do: anchor_classes(anchor_origin)),
      transition_classes(transition, anchor_origin),
      Elevation.class(elevation)
    ]
  end

  defp surface_classes("default"), do: "bg-pp-on-surface text-pp-surface"
  defp surface_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp surface_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp surface_classes("accent"), do: "bg-pp-accent text-pp-on-accent"
  defp surface_classes("error"), do: "bg-pp-error text-pp-on-error"

  defp close_button_classes("default"),
    do: "text-pp-surface/80 hover:bg-pp-surface/10 hover:text-pp-surface"

  defp close_button_classes("primary"),
    do: "text-pp-on-primary/80 hover:bg-pp-on-primary/10 hover:text-pp-on-primary"

  defp close_button_classes("secondary"),
    do: "text-pp-on-secondary/80 hover:bg-pp-on-secondary/10 hover:text-pp-on-secondary"

  defp close_button_classes("accent"),
    do: "text-pp-on-accent/80 hover:bg-pp-on-accent/10 hover:text-pp-on-accent"

  defp close_button_classes("error"),
    do: "text-pp-on-error/80 hover:bg-pp-on-error/10 hover:text-pp-on-error"

  defp timer_bar_classes("default"), do: "bg-pp-surface/40"
  defp timer_bar_classes("primary"), do: "bg-pp-on-primary/40"
  defp timer_bar_classes("secondary"), do: "bg-pp-on-secondary/40"
  defp timer_bar_classes("accent"), do: "bg-pp-on-accent/40"
  defp timer_bar_classes("error"), do: "bg-pp-on-error/40"

  defp anchor_classes("bottom-left"), do: "fixed inset-x-4 bottom-4 sm:inset-x-auto sm:left-4"

  defp anchor_classes("bottom-center"),
    do: "fixed inset-x-4 bottom-4 sm:inset-x-auto sm:left-1/2 sm:-translate-x-1/2"

  defp anchor_classes("bottom-right"), do: "fixed inset-x-4 bottom-4 sm:inset-x-auto sm:right-4"
  defp anchor_classes("top-left"), do: "fixed inset-x-4 top-4 sm:inset-x-auto sm:left-4"

  defp anchor_classes("top-center"),
    do: "fixed inset-x-4 top-4 sm:inset-x-auto sm:left-1/2 sm:-translate-x-1/2"

  defp anchor_classes("top-right"), do: "fixed inset-x-4 top-4 sm:inset-x-auto sm:right-4"

  defp transition_classes("none", _anchor_origin), do: ""
  defp transition_classes("fade", _anchor_origin), do: "pp-snackbar-fade"
  defp transition_classes("grow", _anchor_origin), do: "pp-snackbar-grow"
  defp transition_classes("slide", "top-left"), do: "pp-snackbar-slide-down"
  defp transition_classes("slide", "top-center"), do: "pp-snackbar-slide-down"
  defp transition_classes("slide", "top-right"), do: "pp-snackbar-slide-down"
  defp transition_classes("slide", _bottom_anchor), do: "pp-snackbar-slide-up"
end
