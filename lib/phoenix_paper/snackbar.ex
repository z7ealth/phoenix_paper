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

  Deliberately presentation-only — positioning (`anchor_origin`), the dark
  inverted-surface chip, a mount-in `transition`, and the optional `:action`
  slot, nothing else. A few things MUI's `Snackbar` has that this doesn't,
  and why:

  - **No `autoHideDuration`.** Auto-dismiss-after-a-few-seconds is one
    `Process.send_after/3` in your LiveView clearing whatever assign
    controls `open` — the same mechanism `mix phx.new`'s generated flash
    messages already use. A client-side JS timer here would just be a
    second, redundant way to do the same thing, and one that can drift out
    of sync with the server's own idea of whether the message is still
    live.
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

  Always uses `bg-pp-on-surface`/`text-pp-surface` regardless of the current
  theme — an *inverted* surface (dark chip on a light theme, light chip on a
  dark theme) is the Material spec for a snackbar, not a themed surface like
  `PhoenixPaper.Paper`.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers}

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

  attr(:elevation, :integer, default: 6)
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
      class={Helpers.classes(@paperize, paper_classes(@anchor_origin, @transition, @elevation), @class)}
      {@rest}
    >
      <div class="text-sm">{render_slot(@inner_block)}</div>
      <div :if={@action != []} class="flex shrink-0 items-center">{render_slot(@action)}</div>
    </div>
    """
  end

  defp paper_classes(anchor_origin, transition, elevation) do
    [
      "z-50 mx-auto flex w-fit max-w-md items-center gap-4 rounded-lg bg-pp-on-surface px-4 py-3 text-pp-surface",
      anchor_classes(anchor_origin),
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
