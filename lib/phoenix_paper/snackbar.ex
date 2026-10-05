defmodule PhoenixPaper.Snackbar do
  @moduledoc """
  An MD3 snackbar (`pp_snackbar/1`): a brief message at the bottom of the
  screen, with an optional action and close button.

      <.pp_snackbar open={@message != nil}>
        {@message}
        <:action>
          <.pp_button variant="text" phx-click="undo">Undo</.pp_button>
        </:action>
      </.pp_snackbar>

  For Phoenix flash messages, use `PhoenixPaper.Flash.pp_flash_group/1`,
  which renders them as snackbars.

  ## Look

  MD3's snackbar: an `inverse-surface` container (dark on a light theme,
  light on a dark one) with `body-medium` text, 4dp corners and a level-3
  shadow. Buttons in `:action` get MD3's `inverse-primary` label color
  automatically (a descendant selector on `pp_button`), so a plain
  `<.pp_button variant="text">Undo</.pp_button>` is right. `two_line`
  stacks a long message above its action, MD3's "longer action" layout.
  `on_close` adds MD3's optional close icon button.

  It sits at the bottom of the viewport, centered on compact screens and
  at the bottom-start corner from `sm` up, and enters with MD3's
  fade-and-expand. `positioned={false}` drops the `fixed` placement so you
  can place it yourself (`PhoenixPaper.Flash` stacks several that way).

  ## Dismissing

  `open={false}` removes it. The server usually owns that (a
  `Process.send_after/3` clearing the assign that drives `open`). For a
  client-side timeout, set `auto_hide_duration` (milliseconds, MD3
  suggests 4–10 seconds) together with `on_close`: a CSS animation of that
  length clicks the close button when it ends, no JS hook. There's no
  exit animation (the element is removed with `:if`) and no queue:
  render one snackbar for the message you're currently showing.

  ## Migrating from 0.4

  `anchor_origin` and `transition` are gone (MD3 places snackbars at the
  bottom and gives them one motion), and the auto-hide countdown bar is no
  longer drawn.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Elevation, Helpers}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:open, :boolean, default: true)

  attr(:two_line, :boolean, default: false, doc: "message above the action (MD3 longer action)")

  attr(:positioned, :boolean,
    default: true,
    doc:
      "keep the viewport-anchored `fixed` positioning — set false to drop it and place the chip yourself (e.g. inside PhoenixPaper.Flash's stack)"
  )

  attr(:on_close, JS,
    default: nil,
    doc: "when set, renders MD3's trailing close icon button, running this"
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
      class={
        Helpers.classes(
          @paperize,
          paper_classes(@positioned, @two_line),
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
        class="pp-snackbar-timeout pointer-events-none absolute size-0"
        style={"--pp-snackbar-timeout: #{@auto_hide_duration}ms"}
        onanimationend="var b=this.parentNode.querySelector('[data-pp-snackbar-close]');if(b){b.click()}"
      />
    </div>
    """
  end

  defp paper_classes(positioned, two_line) do
    [
      "relative z-50 mx-auto flex w-fit min-w-[min(344px,100%)] max-w-[672px] items-center gap-x-2 overflow-hidden rounded-pp-xs ps-4 pe-2 pp-body-medium pp-snackbar-enter",
      "bg-pp-inverse-surface text-pp-inverse-on-surface [&_[data-pp-component=button]]:text-pp-inverse-primary",
      two_line && "flex-wrap",
      Elevation.class(3),
      positioned && "fixed inset-x-4 bottom-4 sm:inset-x-auto sm:start-6 sm:bottom-6"
    ]
  end
end
