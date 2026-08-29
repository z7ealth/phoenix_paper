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
    implemented with a zero-footprint CSS animation whose `animationend`
    clicks the close button, no JS hook (the same "small vanilla snippet"
    philosophy as `PhoenixPaper.Ripple`). It's off by default because the
    server is usually the better owner of "is this message still live" —
    one `Process.send_after/3` clearing whatever assign controls `open`,
    the mechanism `mix phx.new`'s generated flash already uses. Use the
    client timer when there's no server round-trip to hang it off (a
    purely client-dismissed flash via `JS.push("lv:clear-flash")`).
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

  Always uses `bg-pp-on-surface`/`text-pp-surface` regardless of the current
  theme — an *inverted* surface (dark chip on a light theme, light chip on a
  dark theme) is the Material spec for a snackbar, not a themed surface like
  `PhoenixPaper.Paper`.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Elevation, Helpers}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:open, :boolean, default: true)

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
      class={Helpers.classes(@paperize, paper_classes(@anchor_origin, @transition, @elevation, @positioned), @class)}
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
        class="-mr-1 inline-flex size-8 shrink-0 cursor-pointer items-center justify-center rounded-full text-pp-surface/80 transition-colors hover:bg-pp-surface/10 hover:text-pp-surface"
      >
        <.pp_icon name="hero-x-mark-mini" class="!size-4" />
      </button>
      <span
        :if={@on_close && @auto_hide_duration}
        aria-hidden="true"
        class="pp-snackbar-timeout pointer-events-none absolute"
        style={"--pp-snackbar-timeout: #{@auto_hide_duration}ms"}
        onanimationend="var b=this.parentNode.querySelector('[data-pp-snackbar-close]');if(b){b.click()}"
      />
    </div>
    """
  end

  defp paper_classes(anchor_origin, transition, elevation, positioned) do
    [
      "relative z-50 mx-auto flex w-fit max-w-md items-center gap-4 rounded-lg bg-pp-on-surface px-4 py-3 text-pp-surface",
      if(positioned, do: anchor_classes(anchor_origin)),
      transition_classes(transition, anchor_origin),
      Elevation.class(elevation)
    ]
  end

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
