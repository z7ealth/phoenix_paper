defmodule PhoenixPaper.TimePicker do
  @moduledoc """
  An MD3 time picker — the dial and the keyboard input mode — as a
  `Phoenix.LiveComponent` (LiveView only).

      <.live_component
        module={PhoenixPaper.TimePicker}
        id="starts-at"
        field={@form[:starts_at]}
        label="Start time"
      />

  An outlined text field shows the time; it (or its clock icon button)
  opens MD3's time picker dialog:

  - the **time selector**: hour and minute boxes in `display-large`
    (the active one `primary-container`), and — for `hour_cycle={12}`
    (default) — a vertical AM/PM segment (`tertiary-container` selected);
  - the **dial**: a 256dp `surface-container-highest` clock face with a
    `primary` hand and selector. Pick the hour, and it moves on to the
    minutes (in steps of 5 on the dial; any minute in input mode).
    `hour_cycle={24}` puts 13–00 on an inner ring;
  - the **input mode** (keyboard icon): two numeric fields instead of the
    dial, MD3's keyboard entry;
  - Cancel / OK — nothing changes until OK.

  The dial is server-rendered: numbers and the hand are positioned with
  inline numeric styles computed from the angle (not dynamic class names,
  see AGENTS.md "Tailwind class safety"), with MD3's selector circle at the
  hand's tip. Clicking a number picks it (minutes in steps of 5). With the
  optional JS hook (see `PhoenixPaper.Helpers.hook/1`) you can also
  **drag the hand**: the hook turns the pointer's angle (and, on a 24-hour
  dial, its distance from the center for the inner ring) into an hour or
  an exact minute and sends it to the component as you move; releasing on
  an hour moves on to the minutes. Without the hook, input mode is the way
  to an exact minute.

  ## Value and forms

  `value` (or `field=`) is a `Time`, an `"HH:MM"` string or `nil`. The
  time is submitted from a hidden input under `name` as 24-hour `HH:MM`,
  and each change dispatches an `input` event from it so the surrounding
  form's `phx-change` runs (the `PhoenixPaper.PowerSelect` mechanism).
  `on_change` (a `Time | nil -> any` function) is called on every change.

  ## Attributes

  `id` (required), `name`, `value`, `field`, `label`, `hour_cycle` (12 or
  24), `supporting_text`, `errors`, `disabled`, `on_change`,
  `headline_label` ("Select time" / "Enter time" in input mode via
  `input_headline_label`), `cancel_label`, `ok_label`, `am_label`,
  `pm_label`, `paperize`, `class`.
  """
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.Button, only: [pp_button: 1]
  import PhoenixPaper.TextField, only: [pp_text_field: 1]

  @defaults [
    name: nil,
    value: nil,
    field: nil,
    label: nil,
    hour_cycle: 12,
    supporting_text: nil,
    errors: [],
    disabled: false,
    on_change: nil,
    headline_label: "Select time",
    input_headline_label: "Enter time",
    cancel_label: "Cancel",
    ok_label: "OK",
    am_label: "AM",
    pm_label: "PM",
    paperize: true,
    class: nil
  ]

  @dial 256
  @outer_r 100
  @inner_r 64

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       open: false,
       selecting: :hour,
       input_mode: false,
       selected: nil,
       pending: ~T[00:00:00],
       external_value: :unset,
       change_count: 0
     )}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      @defaults
      |> Enum.reduce(assign(socket, assigns), fn {key, default}, socket ->
        assign_new(socket, key, fn -> default end)
      end)
      |> apply_field(assigns)
      |> seed()

    {:ok, socket}
  end

  defp apply_field(%{assigns: %{field: %Phoenix.HTML.FormField{} = field}} = socket, assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assign(socket,
      name: socket.assigns.name || field.name,
      value: if(is_nil(assigns[:value]), do: field.value, else: assigns[:value]),
      errors: Enum.map(errors, &Helpers.translate_error/1)
    )
  end

  defp apply_field(socket, _assigns), do: socket

  defp seed(%{assigns: %{external_value: same, value: same}} = socket), do: socket

  defp seed(socket) do
    time = to_time(socket.assigns.value)

    assign(socket,
      selected: time,
      pending: time || ~T[00:00:00],
      external_value: socket.assigns.value
    )
  end

  @doc false
  def to_time(%Time{} = time), do: %{time | second: 0, microsecond: {0, 0}}

  def to_time(value) when is_binary(value) and value != "" do
    value = if String.length(value) == 5, do: value <> ":00", else: value

    case Time.from_iso8601(value) do
      {:ok, time} -> %{time | second: 0, microsecond: {0, 0}}
      _ -> nil
    end
  end

  def to_time(_value), do: nil

  # ---- events ----

  @impl true
  def handle_event("open", _params, %{assigns: %{disabled: true}} = socket),
    do: {:noreply, socket}

  def handle_event("open", _params, socket) do
    {:noreply,
     assign(socket,
       open: true,
       selecting: :hour,
       input_mode: false,
       pending: socket.assigns.selected || ~T[00:00:00]
     )}
  end

  def handle_event("close", _params, socket), do: {:noreply, assign(socket, open: false)}

  def handle_event("select", %{"part" => part}, socket),
    do: {:noreply, assign(socket, selecting: String.to_existing_atom(part))}

  def handle_event("hour", %{"hour" => hour}, socket) do
    hour = String.to_integer(hour)

    hour =
      if socket.assigns.hour_cycle == 12,
        do: to_24(hour, period(socket.assigns.pending)),
        else: hour

    {:noreply,
     assign(socket, pending: %{socket.assigns.pending | hour: hour}, selecting: :minute)}
  end

  # From the optional hook dragging the hand: any hour or any minute, and
  # on release (`done`) after an hour, move on to the minutes like a click.
  def handle_event("dial", %{"part" => "hour", "value" => hour} = params, socket) do
    hour = if is_binary(hour), do: String.to_integer(hour), else: hour

    hour =
      if socket.assigns.hour_cycle == 12,
        do: to_24(hour, period(socket.assigns.pending)),
        else: hour

    socket = assign(socket, pending: %{socket.assigns.pending | hour: hour})
    {:noreply, if(params["done"], do: assign(socket, selecting: :minute), else: socket)}
  end

  def handle_event("dial", %{"part" => "minute", "value" => minute}, socket) do
    minute = if is_binary(minute), do: String.to_integer(minute), else: minute
    {:noreply, assign(socket, pending: %{socket.assigns.pending | minute: rem(minute, 60)})}
  end

  def handle_event("minute", %{"minute" => minute}, socket),
    do:
      {:noreply,
       assign(socket, pending: %{socket.assigns.pending | minute: String.to_integer(minute)})}

  def handle_event("period", %{"period" => p}, socket) do
    %{pending: pending} = socket.assigns
    hour = to_24(to_12(pending.hour), String.to_existing_atom(p))
    {:noreply, assign(socket, pending: %{pending | hour: hour})}
  end

  def handle_event("typed", %{"part" => part, "value" => value}, socket) do
    %{pending: pending, hour_cycle: cycle} = socket.assigns

    pending =
      case {part, Integer.parse(value)} do
        {"hour", {h, _}} when cycle == 12 and h in 1..12 ->
          %{pending | hour: to_24(h, period(pending))}

        {"hour", {h, _}} when cycle == 24 and h in 0..23 ->
          %{pending | hour: h}

        {"minute", {m, _}} when m in 0..59 ->
          %{pending | minute: m}

        _ ->
          pending
      end

    {:noreply, assign(socket, pending: pending)}
  end

  def handle_event("toggle_input", _params, socket),
    do: {:noreply, assign(socket, input_mode: !socket.assigns.input_mode)}

  def handle_event("ok", _params, socket) do
    time = socket.assigns.pending

    socket =
      assign(socket, selected: time, open: false, change_count: socket.assigns.change_count + 1)

    if on_change = socket.assigns.on_change, do: on_change.(time)
    {:noreply, socket}
  end

  defp period(%Time{hour: h}) when h >= 12, do: :pm
  defp period(_time), do: :am

  defp to_12(0), do: 12
  defp to_12(h) when h > 12, do: h - 12
  defp to_12(h), do: h

  defp to_24(12, :am), do: 0
  defp to_24(12, :pm), do: 12
  defp to_24(h, :pm), do: h + 12
  defp to_24(h, :am), do: h

  # ---- render ----

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      data-pp-component="time-picker"
      class={Helpers.classes(@paperize, "relative flex flex-col", @class)}
      phx-window-keydown={@open && "close"}
      phx-key="escape"
      phx-target={@myself}
    >
      <input type="hidden" id={"#{@id}-value"} name={@name} value={@selected && iso(@selected)} />
      <span
        :if={@change_count > 0}
        id={"#{@id}-changed-#{@change_count}"}
        hidden
        phx-mounted={JS.dispatch("input", to: "##{@id}-value")}
      />

      <.pp_text_field
        id={"#{@id}-field"}
        label={@label}
        value={@selected && display(@selected, @hour_cycle, @am_label, @pm_label)}
        readonly
        disabled={@disabled}
        errors={@errors}
        supporting_text={@supporting_text}
        paperize={@paperize}
        aria-haspopup="dialog"
        aria-expanded={to_string(@open)}
        phx-click="open"
        phx-target={@myself}
        class="[&_input]:cursor-pointer"
      >
        <:end_adornment>
          <.pp_icon_button
            icon="hero-clock"
            label={@headline_label}
            disabled={@disabled}
            paperize={@paperize}
            phx-click="open"
            phx-target={@myself}
          />
        </:end_adornment>
      </.pp_text_field>

      <div :if={@open} class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class={["fixed inset-0", @paperize && "bg-pp-scrim/32"]} aria-hidden="true" />
        <div
          id={"#{@id}-panel"}
          role="dialog"
          aria-modal="true"
          aria-label={@headline_label}
          phx-click-away="close"
          phx-target={@myself}
          class={Helpers.classes(@paperize, "relative flex w-[328px] max-w-full flex-col gap-5 rounded-pp-xl bg-pp-surface-container-high p-6 text-pp-on-surface pp-elevation-3", nil)}
        >
          <span class={Helpers.classes(@paperize, "pp-label-medium text-pp-on-surface-variant", nil)}>
            {if @input_mode, do: @input_headline_label, else: @headline_label}
          </span>

          <div class="flex items-start gap-3">
            <div :if={!@input_mode} class="flex items-center gap-1.5">
              <button
                type="button"
                aria-label="Hour"
                aria-pressed={to_string(@selecting == :hour)}
                phx-click="select"
                phx-value-part="hour"
                phx-target={@myself}
                class={Helpers.classes(@paperize, box_classes(@selecting == :hour), nil)}
              >
                {pad(hour_label(@pending.hour, @hour_cycle))}
              </button>
              <span class={Helpers.classes(@paperize, "pp-display-large", nil)}>:</span>
              <button
                type="button"
                aria-label="Minute"
                aria-pressed={to_string(@selecting == :minute)}
                phx-click="select"
                phx-value-part="minute"
                phx-target={@myself}
                class={Helpers.classes(@paperize, box_classes(@selecting == :minute), nil)}
              >
                {pad(@pending.minute)}
              </button>
            </div>

            <div :if={@input_mode} class="flex items-start gap-1.5">
              <label class="flex flex-col gap-1.5">
                <input
                  type="number"
                  inputmode="numeric"
                  min={if @hour_cycle == 12, do: 1, else: 0}
                  max={if @hour_cycle == 12, do: 12, else: 23}
                  form={"#{@id}-detached"}
                  value={hour_label(@pending.hour, @hour_cycle)}
                  phx-blur="typed"
                  phx-value-part="hour"
                  phx-target={@myself}
                  class={Helpers.classes(@paperize, input_box_classes(), nil)}
                />
                <span class={Helpers.classes(@paperize, "pp-body-small text-pp-on-surface-variant", nil)}>Hour</span>
              </label>
              <span class={Helpers.classes(@paperize, "pp-display-medium", nil)}>:</span>
              <label class="flex flex-col gap-1.5">
                <input
                  type="number"
                  inputmode="numeric"
                  min="0"
                  max="59"
                  form={"#{@id}-detached"}
                  value={pad(@pending.minute)}
                  phx-blur="typed"
                  phx-value-part="minute"
                  phx-target={@myself}
                  class={Helpers.classes(@paperize, input_box_classes(), nil)}
                />
                <span class={Helpers.classes(@paperize, "pp-body-small text-pp-on-surface-variant", nil)}>Minute</span>
              </label>
            </div>

            <div
              :if={@hour_cycle == 12}
              role="group"
              aria-label="AM or PM"
              class={Helpers.classes(@paperize, "flex h-20 w-[52px] flex-col overflow-hidden rounded-pp-sm border border-pp-outline", nil)}
            >
              <button
                :for={{p, label} <- [{:am, @am_label}, {:pm, @pm_label}]}
                type="button"
                aria-pressed={to_string(period(@pending) == p)}
                phx-click="period"
                phx-value-period={p}
                phx-target={@myself}
                class={Helpers.classes(@paperize, period_classes(period(@pending) == p, p), nil)}
              >
                {label}
              </button>
            </div>
          </div>

          <div
            :if={!@input_mode}
            id={"#{@id}-dial"}
            data-pp-component="time-picker-dial"
            data-pp-selecting={@selecting}
            data-pp-cycle={@hour_cycle}
            phx-hook={Helpers.hook()}
            class={Helpers.classes(@paperize, "relative mx-auto size-64 shrink-0 touch-none select-none rounded-full bg-pp-surface-container-highest", nil)}
          >
            <span
              :if={@paperize}
              aria-hidden="true"
              class="absolute left-1/2 top-1/2 w-0.5 origin-bottom bg-pp-primary"
              style={hand_style(@pending, @selecting, @hour_cycle)}
            >
              <span class="absolute -top-6 left-1/2 size-12 -translate-x-1/2 rounded-full bg-pp-primary" />
            </span>
            <span :if={@paperize} aria-hidden="true" class="absolute left-1/2 top-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-pp-primary" />
            <button
              :for={{value, label, x, y} <- dial_numbers(@selecting, @hour_cycle)}
              type="button"
              aria-label={label}
              aria-pressed={to_string(dial_selected?(value, @pending, @selecting, @hour_cycle))}
              phx-click={if @selecting == :hour, do: "hour", else: "minute"}
              phx-value-hour={@selecting == :hour && value}
              phx-value-minute={@selecting == :minute && value}
              phx-target={@myself}
              class={Helpers.classes(@paperize, dial_number_classes(dial_selected?(value, @pending, @selecting, @hour_cycle)), nil)}
              style={"left: #{x}px; top: #{y}px"}
            >
              {label}
            </button>
          </div>

          <div class="-mx-3 -mb-3 flex items-center gap-2">
            <.pp_icon_button
              icon={if @input_mode, do: "hero-clock", else: "hero-pencil-square"}
              label={if @input_mode, do: "Switch to clock", else: "Switch to text input"}
              paperize={@paperize}
              phx-click="toggle_input"
              phx-target={@myself}
            />
            <span class="flex-1" />
            <.pp_button variant="text" paperize={@paperize} phx-click="close" phx-target={@myself}>
              {@cancel_label}
            </.pp_button>
            <.pp_button variant="text" paperize={@paperize} phx-click="ok" phx-target={@myself}>
              {@ok_label}
            </.pp_button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp iso(time), do: "#{pad(time.hour)}:#{pad(time.minute)}"

  defp display(time, 24, _am, _pm), do: iso(time)

  defp display(time, 12, am, pm),
    do: "#{to_12(time.hour)}:#{pad(time.minute)} #{if period(time) == :am, do: am, else: pm}"

  defp hour_label(hour, 12), do: to_12(hour)
  defp hour_label(hour, 24), do: hour

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")

  @doc false
  # {value, label, x, y} for each number on the dial: the top-left of its
  # 48px button, around a 256px face. 24-hour dials put 13–00 on an inner
  # ring.
  def dial_numbers(:minute, _cycle) do
    for m <- 0..55//5 do
      {x, y} = polar(m / 60, @outer_r)
      {m, pad(m), x, y}
    end
  end

  def dial_numbers(:hour, 12) do
    for h <- 1..12 do
      {x, y} = polar(rem(h, 12) / 12, @outer_r)
      {h, Integer.to_string(h), x, y}
    end
  end

  def dial_numbers(:hour, 24) do
    outer =
      for h <- 1..12 do
        {x, y} = polar(rem(h, 12) / 12, @outer_r)
        {h, Integer.to_string(h), x, y}
      end

    inner =
      for h <- 13..24 do
        value = rem(h, 24)
        {x, y} = polar(rem(h, 12) / 12, @inner_r)
        {value, pad(value), x, y}
      end

    outer ++ inner
  end

  defp polar(fraction, r) do
    theta = 2 * :math.pi() * fraction
    c = @dial / 2
    {Float.round(c + r * :math.sin(theta) - 24, 1), Float.round(c - r * :math.cos(theta) - 24, 1)}
  end

  defp dial_selected?(value, pending, :minute, _cycle), do: value == pending.minute
  defp dial_selected?(value, pending, :hour, 12), do: value == to_12(pending.hour)
  defp dial_selected?(value, pending, :hour, 24), do: value == pending.hour

  # The hand: from the center to the selected number, rotated around its
  # bottom end (the center).
  defp hand_style(pending, :minute, _cycle), do: hand(pending.minute / 60, @outer_r)

  defp hand_style(pending, :hour, 24) when pending.hour == 0 or pending.hour > 12,
    do: hand(rem(pending.hour, 12) / 12, @inner_r)

  defp hand_style(pending, :hour, _cycle), do: hand(rem(pending.hour, 12) / 12, @outer_r)

  defp hand(fraction, r) do
    "height: #{r}px; transform: translate(-50%, -100%) rotate(#{Float.round(fraction * 360, 2)}deg); transform-origin: 50% 100%"
  end

  defp box_classes(true),
    do:
      "relative inline-flex h-20 w-24 cursor-pointer items-center justify-center overflow-hidden rounded-pp-sm bg-pp-primary-container pp-display-large text-pp-on-primary-container pp-state-layer pp-focus-ring"

  defp box_classes(false),
    do:
      "relative inline-flex h-20 w-24 cursor-pointer items-center justify-center overflow-hidden rounded-pp-sm bg-pp-surface-container-highest pp-display-large text-pp-on-surface pp-state-layer pp-focus-ring"

  defp input_box_classes,
    do:
      "h-[72px] w-24 rounded-pp-sm border-2 border-transparent bg-pp-surface-container-highest text-center pp-display-medium text-pp-on-surface outline-none [appearance:textfield] focus:border-pp-primary focus:bg-pp-primary-container focus:text-pp-on-primary-container [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"

  defp period_classes(selected, p) do
    [
      "relative flex flex-1 cursor-pointer items-center justify-center overflow-hidden pp-title-medium pp-state-layer pp-focus-ring",
      p == :pm && "border-t border-pp-outline",
      if(selected,
        do: "bg-pp-tertiary-container text-pp-on-tertiary-container",
        else: "text-pp-on-surface-variant"
      )
    ]
  end

  defp dial_number_classes(true),
    do:
      "absolute inline-flex size-12 cursor-pointer items-center justify-center rounded-full bg-pp-primary pp-body-large text-pp-on-primary pp-focus-ring"

  defp dial_number_classes(false),
    do:
      "absolute inline-flex size-12 cursor-pointer items-center justify-center overflow-hidden rounded-full pp-body-large text-pp-on-surface pp-state-layer pp-focus-ring"
end
