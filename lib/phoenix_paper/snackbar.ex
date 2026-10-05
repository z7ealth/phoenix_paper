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

  ## Look

  MD3's snackbar: an `inverse-surface` chip (dark on a light theme, light
  on a dark one) with `body-medium` text, 4dp corners and a level-3
  shadow. Buttons in `:action` get MD3's `inverse-primary` label color
  automatically (a descendant selector on `pp_button`), so a plain
  `<.pp_button variant="text">Undo</.pp_button>` is right. `two_line`
  stacks a long message above its action, MD3's "longer action" layout.

  0.3's `color` attr is gone: MD3 snackbars are always the inverse
  surface. For a colored, severity-coded message use an `Alert` inside a
  `paperize={false}` snackbar (above).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Elevation, Helpers}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:open, :boolean, default: true)

  attr(:two_line, :boolean, default: false, doc: "message above the action (MD3 longer action)")

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
          paper_classes(@anchor_origin, @transition, @positioned, @two_line),
          @class
        )
      }
      {@rest}
    >
      <div class={["min-w-0 py-3.5", @two_line && "w-full"]}>{render_slot(@inner_block)}</div>
      <div
        :if={@action != []}
        class={["flex shrink-0 items-center gap-1 -me-2", @two_line && "ms-auto -mt-2 mb-1"]}
      >
        {render_slot(@action)}
      </div>
      <button
        :if={@on_close}
        type="button"
        data-pp-snackbar-close
        phx-click={@on_close}
        aria-label="Close"
        class={
          Helpers.classes(
            @paperize,
            "relative -me-2 inline-flex size-10 shrink-0 cursor-pointer items-center justify-center rounded-full text-pp-inverse-on-surface pp-state-layer pp-focus-ring",
            nil
          )
        }
      >
        <.pp_icon name="hero-x-mark" size="sm" />
      </button>
      <span
        :if={@on_close && @auto_hide_duration}
        aria-hidden="true"
        class={[
          "pp-snackbar-timeout pointer-events-none absolute",
          Helpers.classes(@paperize, "inset-x-0 bottom-0 h-1 bg-pp-inverse-primary/60", nil)
        ]}
        style={"--pp-snackbar-timeout: #{@auto_hide_duration}ms"}
        onanimationend="var b=this.parentNode.querySelector('[data-pp-snackbar-close]');if(b){b.click()}"
      />
    </div>
    """
  end

  defp paper_classes(anchor_origin, transition, positioned, two_line) do
    [
      "relative z-50 mx-auto flex w-fit min-w-[min(344px,100%)] max-w-[672px] items-center gap-x-2 overflow-hidden rounded-pp-xs ps-4 pe-2 pp-body-medium",
      "bg-pp-inverse-surface text-pp-inverse-on-surface [&_[data-pp-component=button]]:text-pp-inverse-primary",
      two_line && "flex-wrap",
      Elevation.class(3),
      if(positioned, do: anchor_classes(anchor_origin)),
      transition_classes(transition, anchor_origin)
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
