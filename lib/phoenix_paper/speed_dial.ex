defmodule PhoenixPaper.SpeedDial do
  @moduledoc """
  A Floating Action Button that reveals a small set of related actions
  (`pp_speed_dial/1`), in the spirit of MUI's
  [`SpeedDial`](https://mui.com/material-ui/react-speed-dial/) +
  `SpeedDialAction`.

      <.pp_speed_dial id="create" label="Create" class="fixed bottom-6 right-6">
        <:action label="New workbook" navigate={~p"/workbooks/new"}>
          <.pp_icon name="hero-document-plus" />
        </:action>
        <:action label="Invite teammate" on_click={JS.push("open_invite")}>
          <.pp_icon name="hero-user-plus" />
        </:action>
      </.pp_speed_dial>

  Like `PhoenixPaper.Fab`, it's the caller's job to anchor the whole thing
  to a corner (`class="fixed bottom-6 right-6"`); `direction` then picks
  which way the actions fan out from there (`up` — the default — `down`,
  `left`, `right`).

  ## Pure CSS — opens on hover, click, or keyboard focus

  No JS, no LiveView, no hook — the same hidden-checkbox-plus-`peer-checked:`
  trick as `PhoenixPaper.Drawer`/`PhoenixPaper.Accordion`, combined with
  Tailwind's `group-hover:`/`group-focus-within:` (the `PhoenixPaper.Tooltip`
  mechanism). The result matches MUI's own behaviour closely:

  - **Hover** the trigger (or the actions) → the dial opens, and closes
    again when the pointer leaves (`group-hover:`). The gap between the
    trigger and the first action is *padding*, not margin, so it stays part
    of the hover target and the dial doesn't flicker shut crossing it.
  - **Click/tap** the trigger → the checkbox toggles and the dial *stays*
    open (`peer-checked:`) until clicked again — the touch-device path,
    where there's no hover.
  - **Tab** to the trigger and the dial opens (`group-focus-within:`),
    staying open while focus moves through the actions.

  What a stateless, JS-free component can't do, and MUI can: set
  `aria-expanded` on the trigger (it changes with a state a CSS-only
  component never names), close on <kbd>Esc</kbd> or an outside click
  beyond "the pointer left" / "focus left", and the `SpeedDialAction`
  hover-tooltips — here each `:action`'s `label` renders as an always-shown
  pill next to it (MUI's `tooltipOpen` look), which needs no positioning JS.

  ## The trigger icon

  The `:icon` slot is the closed-state icon (default: `hero-plus`). With no
  `:open_icon`, it just rotates 45° when the dial opens — turning a `+`
  into an `✕`, MUI's default `SpeedDialIcon` behaviour. Give an `:open_icon`
  slot instead and the two cross-fade (MUI's `openIcon`).

  ## `:action`

  Each `:action` slot's body is its icon; `label` is the pill text. An
  action is a link when given `href`/`navigate`/`patch` (rendered through
  `Phoenix.Component.link/1`, like `PhoenixPaper.Button`'s link mode),
  otherwise a `<button>` — pass `on_click` (a `Phoenix.LiveView.JS` or a
  plain event name) for the `phx-click`.

  Ripple (see `PhoenixPaper.Ripple`) is on by default for the trigger and
  every action; `ripple={false}` turns it off, and `paperize={false}` does
  too (along with all positioning/reveal styling — a de-paperized speed
  dial is just the bare elements for you to skin).
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Ripple}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :string, required: true, doc: "used to wire the trigger label to its toggle checkbox")

  attr(:label, :string,
    required: true,
    doc: "accessible name for the trigger button (MUI's ariaLabel)"
  )

  attr(:direction, :string,
    default: "up",
    values: ~w(up down left right),
    doc: "which way the actions fan out from the trigger"
  )

  attr(:color, :string, default: "secondary", values: ~w(primary secondary tertiary error))
  attr(:size, :string, default: "md", values: ~w(sm md lg))

  attr(:default_open, :boolean,
    default: false,
    doc: "render initially open — an uncontrolled checkbox, no server wiring (see Drawer)"
  )

  attr(:ripple, :boolean,
    default: true,
    doc: "the ripple effect on the trigger and actions — off whenever paperize is false"
  )

  attr(:paperize, :boolean, default: true)

  attr(:class, :any,
    default: nil,
    doc: "merged onto the trigger — put your `fixed`/corner anchoring here"
  )

  attr(:rest, :global)

  slot(:icon, doc: "the closed-state trigger icon (default: hero-plus)")

  slot(:open_icon,
    doc: "a distinct icon to cross-fade to when open, instead of rotating :icon 45°"
  )

  slot :action, doc: "one action FAB — the slot body is its icon" do
    attr(:label, :string, doc: "pill text shown next to the action")
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:on_click, :any, doc: "a Phoenix.LiveView.JS command or event name for phx-click")
  end

  @doc "Renders a speed dial. See the module doc."
  def pp_speed_dial(assigns) do
    assigns = assign(assigns, :ripple?, assigns.ripple and assigns.paperize)

    ~H"""
    <div data-pp-component="speed-dial" class="group relative inline-flex" {@rest}>
      <input
        type="checkbox"
        id={"#{@id}-toggle"}
        checked={@default_open}
        aria-label={@label}
        class="peer sr-only"
      />
      <label
        for={"#{@id}-toggle"}
        onclick={Ripple.on_click(@ripple?)}
        class={Helpers.classes(@paperize, trigger_classes(@color, @size, @ripple?), @class)}
      >
        <span
          :if={@open_icon == []}
          class="inline-flex transition-transform duration-200 peer-checked:rotate-45 group-hover:rotate-45 group-focus-within:rotate-45"
        >
          {trigger_icon(assigns)}
        </span>
        <span :if={@open_icon != []} class="relative inline-flex">
          <span class="inline-flex transition-opacity peer-checked:opacity-0 group-hover:opacity-0 group-focus-within:opacity-0">
            {trigger_icon(assigns)}
          </span>
          <span class="absolute inset-0 inline-flex items-center justify-center opacity-0 transition-opacity peer-checked:opacity-100 group-hover:opacity-100 group-focus-within:opacity-100">
            {render_slot(@open_icon)}
          </span>
        </span>
      </label>
      <div class={Helpers.classes(@paperize, actions_container_classes(@direction), nil)}>
        <.speed_dial_action
          :for={action <- @action}
          action={action}
          direction={@direction}
          ripple?={@ripple?}
          paperize={@paperize}
        />
      </div>
    </div>
    """
  end

  defp trigger_icon(assigns) do
    ~H"""
    <span :if={@icon != []} class="inline-flex">{render_slot(@icon)}</span>
    <.pp_icon :if={@icon == []} name="hero-plus" />
    """
  end

  attr(:action, :any, required: true)
  attr(:direction, :string, required: true)
  attr(:ripple?, :boolean, required: true)
  attr(:paperize, :boolean, required: true)

  defp speed_dial_action(assigns) do
    linked? =
      assigns.action[:href] not in [nil, false] or
        assigns.action[:navigate] not in [nil, false] or
        assigns.action[:patch] not in [nil, false]

    assigns = assign(assigns, :linked?, linked?)

    ~H"""
    <div class={Helpers.classes(@paperize, row_classes(@direction), nil)}>
      <span :if={@action[:label]} class={Helpers.classes(@paperize, pill_classes(), nil)}>
        {@action[:label]}
      </span>
      <.link
        :if={@linked?}
        href={@action[:href]}
        navigate={@action[:navigate]}
        patch={@action[:patch]}
        onclick={Ripple.on_click(@ripple?)}
        data-pp-component="speed-dial-action"
        class={Helpers.classes(@paperize, action_button_classes(@ripple?), nil)}
      >
        {render_slot(@action)}
      </.link>
      <button
        :if={!@linked?}
        type="button"
        phx-click={@action[:on_click]}
        onclick={Ripple.on_click(@ripple?)}
        data-pp-component="speed-dial-action"
        class={Helpers.classes(@paperize, action_button_classes(@ripple?), nil)}
      >
        {render_slot(@action)}
      </button>
    </div>
    """
  end

  defp trigger_classes(color, size, ripple) do
    [
      "inline-flex cursor-pointer items-center justify-center rounded-full transition-shadow hover:pp-elevation-8",
      "peer-focus-visible:outline peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2",
      trigger_size(size),
      trigger_color(color),
      Elevation.class(6),
      Ripple.container_classes(ripple)
    ]
  end

  defp trigger_size("sm"), do: "size-10"
  defp trigger_size("md"), do: "size-14"
  defp trigger_size("lg"), do: "size-16"

  defp trigger_color("primary"),
    do: "bg-pp-primary text-pp-on-primary peer-focus-visible:outline-pp-primary"

  defp trigger_color("secondary"),
    do: "bg-pp-secondary text-pp-on-secondary peer-focus-visible:outline-pp-secondary"

  defp trigger_color("tertiary"),
    do: "bg-pp-tertiary text-pp-on-tertiary peer-focus-visible:outline-pp-tertiary"

  defp trigger_color("error"),
    do: "bg-pp-error text-pp-on-error peer-focus-visible:outline-pp-error"

  # Absolutely positioned off the trigger, so opening the dial never shifts
  # the trigger itself. Hidden by default (`opacity-0 pointer-events-none`),
  # revealed by ANY of checkbox-checked / group-hover / group-focus-within.
  # The `p*-4` on the fan-out side is padding, not margin — it keeps the gap
  # between trigger and first action inside the hover target.
  defp actions_container_classes(direction) do
    [
      "absolute flex gap-3",
      "scale-95 opacity-0 pointer-events-none transition-[opacity,transform] duration-150",
      "peer-checked:scale-100 peer-checked:opacity-100 peer-checked:pointer-events-auto",
      "group-hover:scale-100 group-hover:opacity-100 group-hover:pointer-events-auto",
      "group-focus-within:scale-100 group-focus-within:opacity-100 group-focus-within:pointer-events-auto",
      container_direction(direction)
    ]
  end

  defp container_direction("up"),
    do: "bottom-full left-1/2 -translate-x-1/2 origin-bottom flex-col-reverse items-center pb-4"

  defp container_direction("down"),
    do: "top-full left-1/2 -translate-x-1/2 origin-top flex-col items-center pt-4"

  defp container_direction("left"),
    do: "right-full top-1/2 -translate-y-1/2 origin-right flex-row-reverse items-center pr-4"

  defp container_direction("right"),
    do: "left-full top-1/2 -translate-y-1/2 origin-left flex-row items-center pl-4"

  # up/down fan vertically → pill sits to the left of each action;
  # left/right fan horizontally → pill sits above each action.
  defp row_classes(direction) when direction in ~w(up down),
    do: "flex flex-row items-center gap-3"

  defp row_classes(_direction), do: "flex flex-col items-center gap-1"

  defp pill_classes do
    "pointer-events-none whitespace-nowrap rounded bg-pp-on-surface/90 px-2 py-1 text-xs font-medium text-pp-surface shadow"
  end

  defp action_button_classes(ripple) do
    [
      "inline-flex size-10 shrink-0 cursor-pointer items-center justify-center rounded-full bg-pp-surface text-pp-on-surface transition-shadow hover:pp-elevation-4",
      "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pp-primary",
      Elevation.class(3),
      Ripple.container_classes(ripple)
    ]
  end
end
