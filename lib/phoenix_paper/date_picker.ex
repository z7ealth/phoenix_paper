defmodule PhoenixPaper.DatePicker do
  @moduledoc """
  An MD3 date picker — docked or modal — as a `Phoenix.LiveComponent`
  (LiveView only).

      <.live_component
        module={PhoenixPaper.DatePicker}
        id="due-on"
        field={@form[:due_on]}
        label="Due date"
        min={Date.utc_today()}
      />

  It's a `LiveComponent` because a calendar has state a single render
  can't hold: the month being viewed, the year list, and (modal) a pending
  choice until OK.

  ## Variants

  - `docked` (default): an outlined text field showing the date, with a
    calendar icon button; the calendar opens in a `surface-container-high`
    panel under the field (16dp corners, level-3 shadow). Picking a day
    commits and closes. Click outside or Escape closes.
  - `modal`: the field opens MD3's modal date picker — a centered
    28dp-corner dialog with a "Select date" header, the pending date as a
    `headline-large` headline, the calendar, and Cancel / OK. The pencil
    button in the header switches to **input mode** (a native date input,
    MD3's keyboard entry).

  ## The calendar

  A month header (a button that switches to a year grid, plus previous/
  next month icon buttons) over a 7-column grid of 40dp day buttons: the
  selected day is filled `primary`, today has a `primary` outline, days
  outside `min`/`max` are disabled. `first_day_of_week` (1 = Monday ..
  7 = Sunday, default 7) and `month_names`/`weekday_names` localize it;
  `format` (a `Date -> String` function, default ISO 8601) is what the
  field shows.

  ## Date ranges

  `range` turns it into MD3's date range picker. The first pick starts the
  range, the second ends it (swapped if it's earlier), and a third starts
  a new one. The days between are drawn on a `secondary-container` band
  that meets the two `primary` endpoint circles. A docked range picker
  commits and closes on the second pick; a modal one on OK (OK after one
  pick gives a one-day range). Input mode shows a start and an end field.

  The value is a `{start, end}` tuple (also accepted: a two-element list
  or a map with `start`/`end`), submitted as `"\#{name}_start"` and
  `"\#{name}_end"`, the way `PhoenixPaper.Slider` splits its range. The
  field shows `start – end`, and `on_change` receives the tuple.
  `range_headline_label`, `start_label` and `end_label` translate it.

  ## Value and forms

  `value` (or `field=`) is a `Date`, an ISO 8601 string or `nil`. The
  date is submitted from a hidden input under `name` as `YYYY-MM-DD`, and
  every change dispatches an `input` event from it — so the surrounding
  form's `phx-change` runs, as for a native input (a freshly-id'd
  `phx-mounted` span after each change dispatches it). Outside
  a form, `on_change` (a `Date | nil -> any` function, run in the LiveView
  process) is called on every change. `clearable` adds a Clear action.
  The parent's `value` is re-read only when it changes.

  ## Attributes

  `id` (required), `name`, `value`, `field`, `label`, `variant`, `range`, `min`,
  `max`, `first_day_of_week`, `format`, `month_names`, `weekday_names`,
  `supporting_text`, `errors`, `disabled`, `clearable`, `on_change`,
  `cancel_label`, `ok_label`, `clear_label`, `headline_label`
  ("Select date"), `paperize`, `class`.
  """
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.Button, only: [pp_button: 1]
  import PhoenixPaper.TextField, only: [pp_text_field: 1]

  @month_names ~w(January February March April May June July August September October November December)
  @weekday_names ~w(M T W T F S S)

  @defaults [
    name: nil,
    value: nil,
    field: nil,
    label: nil,
    variant: "docked",
    range: false,
    min: nil,
    max: nil,
    first_day_of_week: 7,
    format: nil,
    month_names: @month_names,
    weekday_names: @weekday_names,
    supporting_text: nil,
    errors: [],
    disabled: false,
    clearable: false,
    on_change: nil,
    cancel_label: "Cancel",
    ok_label: "OK",
    clear_label: "Clear",
    headline_label: "Select date",
    range_headline_label: "Select dates",
    start_label: "Start date",
    end_label: "End date",
    paperize: true,
    class: nil
  ]

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       open: false,
       mode: :days,
       input_mode: false,
       selected: nil,
       pending: nil,
       view: nil,
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

  # Re-read the parent's value only when it changed (a stale re-render
  # mustn't undo a pick that hasn't round-tripped yet).
  defp seed(%{assigns: %{external_value: same, value: same}} = socket), do: socket

  defp seed(socket) do
    selected = parse_value(socket.assigns.value, socket.assigns.range)

    assign(socket,
      selected: selected,
      pending: selected,
      view: view_for(selected, socket.assigns),
      external_value: socket.assigns.value
    )
  end

  # A range is `{start, end}`; while picking, `end` may be nil.
  defp parse_value(value, false), do: to_date(value)

  defp parse_value({a, b}, true) do
    case {to_date(a), to_date(b)} do
      {nil, _} -> nil
      {start, finish} -> {start, finish}
    end
  end

  defp parse_value([a, b], true), do: parse_value({a, b}, true)

  defp parse_value(%{} = map, true),
    do: parse_value({map[:start] || map["start"], map[:end] || map["end"]}, true)

  defp parse_value(_value, true), do: nil

  defp first_date({start, _}), do: start
  defp first_date(date), do: date

  defp view_for(selected, assigns),
    do: Date.beginning_of_month(first_date(selected) || clamp(Date.utc_today(), assigns))

  # Range picking: the first pick (or any pick after a complete range)
  # starts a new range; the second ends it, swapping if it's earlier.
  @doc false
  def next_range(nil, date), do: {date, nil}
  def next_range({_start, %Date{}}, date), do: {date, nil}

  def next_range({start, nil}, date) do
    if Date.compare(date, start) == :lt, do: {date, start}, else: {start, date}
  end

  defp complete?({_start, %Date{}}), do: true
  defp complete?(_range), do: false

  @doc false
  def to_date(%Date{} = date), do: date

  def to_date(value) when is_binary(value) and value != "" do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  def to_date(_value), do: nil

  defp clamp(date, %{min: min, max: max}) do
    min = to_date(min)
    max = to_date(max)

    cond do
      min && Date.compare(date, min) == :lt -> min
      max && Date.compare(date, max) == :gt -> max
      true -> date
    end
  end

  # ---- events ----

  @impl true
  def handle_event("open", _params, %{assigns: %{disabled: true}} = socket),
    do: {:noreply, socket}

  def handle_event("open", _params, socket) do
    %{selected: selected} = socket.assigns

    {:noreply,
     assign(socket,
       open: true,
       mode: :days,
       input_mode: false,
       pending: selected,
       view: view_for(selected, socket.assigns)
     )}
  end

  def handle_event("close", _params, socket), do: {:noreply, assign(socket, open: false)}

  def handle_event("month", %{"delta" => delta}, socket) do
    view = Date.shift(socket.assigns.view, month: String.to_integer(delta))
    {:noreply, assign(socket, view: view)}
  end

  def handle_event("toggle_years", _params, socket) do
    mode = if socket.assigns.mode == :years, do: :days, else: :years
    {:noreply, assign(socket, mode: mode)}
  end

  def handle_event("year", %{"year" => year}, socket) do
    view = %{socket.assigns.view | year: String.to_integer(year)}
    {:noreply, assign(socket, view: view, mode: :days)}
  end

  def handle_event("pick", %{"date" => iso}, %{assigns: %{range: true}} = socket) do
    range = next_range(socket.assigns.pending, Date.from_iso8601!(iso))

    if socket.assigns.variant == "docked" and complete?(range) do
      {:noreply, socket |> commit(range) |> assign(open: false)}
    else
      {:noreply, assign(socket, pending: range)}
    end
  end

  def handle_event("pick", %{"date" => iso}, socket) do
    date = Date.from_iso8601!(iso)

    if socket.assigns.variant == "modal" do
      {:noreply, assign(socket, pending: date)}
    else
      {:noreply, socket |> commit(date) |> assign(open: false)}
    end
  end

  def handle_event("typed", %{"value" => iso} = params, socket) do
    case {to_date(iso), socket.assigns.range, params["part"]} do
      {nil, _, _} ->
        {:noreply, socket}

      {date, false, _} ->
        {:noreply, assign(socket, pending: date, view: Date.beginning_of_month(date))}

      {date, true, part} ->
        {start, finish} = socket.assigns.pending || {date, nil}
        range = if part == "end", do: {start, date}, else: {date, finish}

        range =
          case range do
            {a, %Date{} = b} -> if Date.compare(b, a) == :lt, do: {b, a}, else: {a, b}
            other -> other
          end

        {:noreply, assign(socket, pending: range, view: view_for(range, socket.assigns))}
    end
  end

  def handle_event("toggle_input", _params, socket),
    do: {:noreply, assign(socket, input_mode: !socket.assigns.input_mode)}

  # A range confirmed after only its first pick is a one-day range.
  def handle_event("ok", _params, %{assigns: %{range: true, pending: {start, nil}}} = socket),
    do: {:noreply, socket |> commit({start, start}) |> assign(open: false)}

  def handle_event("ok", _params, socket),
    do: {:noreply, socket |> commit(socket.assigns.pending) |> assign(open: false)}

  def handle_event("clear", _params, socket),
    do: {:noreply, socket |> commit(nil) |> assign(open: false)}

  defp commit(socket, date) do
    socket =
      assign(socket, selected: date, pending: date, change_count: socket.assigns.change_count + 1)

    if on_change = socket.assigns.on_change, do: on_change.(date)
    socket
  end

  # ---- render ----

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:display, display(assigns.selected, assigns.format))
      |> assign(
        :target_date,
        if(assigns.variant == "modal" or assigns.range,
          do: assigns.pending,
          else: assigns.selected
        )
      )
      |> assign(
        :title,
        if(assigns.range, do: assigns.range_headline_label, else: assigns.headline_label)
      )

    ~H"""
    <div
      id={@id}
      data-pp-component="date-picker"
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, "relative flex flex-col", @class)}
      phx-window-keydown={@open && "close"}
      phx-key="escape"
      phx-target={@myself}
    >
      <input
        :if={!@range}
        type="hidden"
        id={"#{@id}-value"}
        name={@name}
        value={@selected && Date.to_iso8601(@selected)}
      />
      <input
        :if={@range}
        type="hidden"
        id={"#{@id}-value"}
        name={@name && "#{@name}_start"}
        value={range_iso(@selected, 0)}
      />
      <input
        :if={@range}
        type="hidden"
        id={"#{@id}-value-end"}
        name={@name && "#{@name}_end"}
        value={range_iso(@selected, 1)}
      />
      <span
        :if={@change_count > 0}
        id={"#{@id}-changed-#{@change_count}"}
        hidden
        phx-mounted={JS.dispatch("input", to: "##{@id}-value")}
      />

      <.pp_text_field
        id={"#{@id}-field"}
        label={@label}
        value={@display}
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
            icon="hero-calendar"
            label={@title}
            disabled={@disabled}
            paperize={@paperize}
            phx-click="open"
            phx-target={@myself}
          />
        </:end_adornment>
      </.pp_text_field>

      <div
        :if={@open && @variant == "docked"}
        id={"#{@id}-panel"}
        role="dialog"
        aria-label={@title}
        phx-click-away="close"
        phx-target={@myself}
        class={Helpers.classes(@paperize, "absolute start-0 top-full z-40 mt-1 w-[360px] max-w-[calc(100vw-2rem)] rounded-pp-lg bg-pp-surface-container-high p-3 text-pp-on-surface pp-elevation-3", nil)}
      >
        {calendar(assigns)}
        <div :if={@clearable} class="mt-2 flex justify-end">
          <.pp_button variant="text" paperize={@paperize} phx-click="clear" phx-target={@myself}>
            {@clear_label}
          </.pp_button>
        </div>
      </div>

      <div :if={@open && @variant == "modal"} class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class={["fixed inset-0", @paperize && "bg-pp-scrim/32"]} aria-hidden="true" />
        <div
          id={"#{@id}-panel"}
          role="dialog"
          aria-modal="true"
          aria-label={@title}
          phx-click-away="close"
          phx-target={@myself}
          class={Helpers.classes(@paperize, "relative w-[360px] max-w-full rounded-pp-xl bg-pp-surface-container-high text-pp-on-surface pp-elevation-3", nil)}
        >
          <div class="flex flex-col gap-9 px-6 pt-4 pb-3">
            <span class={Helpers.classes(@paperize, "pp-label-large text-pp-on-surface-variant", nil)}>
              {@title}
            </span>
            <div class="flex items-center justify-between gap-2">
              <span class={Helpers.classes(@paperize, "pp-headline-large", nil)}>
                {headline(@pending, @month_names)}
              </span>
              <.pp_icon_button
                icon={if @input_mode, do: "hero-calendar", else: "hero-pencil"}
                label={if @input_mode, do: "Switch to calendar", else: "Switch to text input"}
                paperize={@paperize}
                phx-click="toggle_input"
                phx-target={@myself}
              />
            </div>
          </div>
          <div class={Helpers.classes(@paperize, "border-t border-pp-outline-variant", nil)} />
          <div class="p-3">
            <div :if={@input_mode && @range} class="flex flex-col gap-4 px-3 py-4">
              <input
                :for={{part, label, index} <- [{"start", @start_label, 0}, {"end", @end_label, 1}]}
                type="date"
                id={"#{@id}-typed-#{part}"}
                form={"#{@id}-detached"}
                value={range_iso(@pending, index)}
                aria-label={label}
                placeholder={label}
                phx-blur="typed"
                phx-value-part={part}
                phx-target={@myself}
                class={Helpers.classes(@paperize, "h-14 w-full rounded-pp-xs border border-pp-outline bg-transparent px-4 pp-body-large text-pp-on-surface outline-none focus:border-2 focus:border-pp-primary", nil)}
              />
            </div>
            <div :if={@input_mode && !@range} class="px-3 py-4">
              <input
                type="date"
                id={"#{@id}-typed"}
                form={"#{@id}-detached"}
                value={@pending && Date.to_iso8601(@pending)}
                min={@min && to_date(@min) && Date.to_iso8601(to_date(@min))}
                max={@max && to_date(@max) && Date.to_iso8601(to_date(@max))}
                aria-label={@label || @title}
                phx-blur="typed"
                phx-target={@myself}
                class={Helpers.classes(@paperize, "h-14 w-full rounded-pp-xs border border-pp-outline bg-transparent px-4 pp-body-large text-pp-on-surface outline-none focus:border-2 focus:border-pp-primary", nil)}
              />
            </div>
            <div :if={!@input_mode}>{calendar(assigns)}</div>
          </div>
          <div class="flex items-center gap-2 px-3 pb-3">
            <.pp_button :if={@clearable} variant="text" paperize={@paperize} phx-click="clear" phx-target={@myself}>
              {@clear_label}
            </.pp_button>
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

  defp calendar(assigns) do
    assigns =
      assigns
      |> assign(:weeks, weeks(assigns.view, assigns.first_day_of_week))
      |> assign(:weekday_labels, weekday_labels(assigns.weekday_names, assigns.first_day_of_week))
      |> assign(:today, Date.utc_today())

    ~H"""
    <div class="flex items-center gap-1 ps-3">
      <button
        type="button"
        aria-label="Choose year"
        aria-expanded={to_string(@mode == :years)}
        phx-click="toggle_years"
        phx-target={@myself}
        class={Helpers.classes(@paperize, "relative inline-flex h-10 cursor-pointer items-center gap-2 overflow-hidden rounded-pp-full ps-2 pe-1 pp-label-large text-pp-on-surface-variant pp-state-layer pp-focus-ring", nil)}
      >
        {Enum.at(@month_names, @view.month - 1)} {@view.year}
        <PhoenixPaper.Icon.pp_icon
          name="hero-chevron-down"
          size="sm"
          class={["pp-motion-spatial-fast", @mode == :years && "rotate-180"]}
        />
      </button>
      <span class="flex-1" />
      <.pp_icon_button
        :if={@mode == :days}
        icon="hero-chevron-left"
        label="Previous month"
        paperize={@paperize}
        disabled={!month_allowed?(Date.shift(@view, month: -1), @min, @max)}
        phx-click="month"
        phx-value-delta="-1"
        phx-target={@myself}
      />
      <.pp_icon_button
        :if={@mode == :days}
        icon="hero-chevron-right"
        label="Next month"
        paperize={@paperize}
        disabled={!month_allowed?(Date.shift(@view, month: 1), @min, @max)}
        phx-click="month"
        phx-value-delta="1"
        phx-target={@myself}
      />
    </div>

    <div :if={@mode == :days} role="grid" aria-label={"#{Enum.at(@month_names, @view.month - 1)} #{@view.year}"} class="mt-1">
      <div role="row" class="grid grid-cols-7">
        <span
          :for={label <- @weekday_labels}
          role="columnheader"
          class={Helpers.classes(@paperize, "flex h-12 items-center justify-center pp-body-large text-pp-on-surface", nil)}
        >
          {label}
        </span>
      </div>
      <div :for={week <- @weeks} role="row" class="grid grid-cols-7">
        <span
          :for={day <- week}
          role="gridcell"
          class={[
            "flex h-12 items-center justify-center",
            @paperize && day && range_band(@range, @target_date, day)
          ]}
        >
          <button
            :if={day}
            type="button"
            aria-label={Date.to_iso8601(day)}
            aria-selected={to_string(selected_day?(@range, @target_date, day))}
            aria-current={day == @today && "date"}
            disabled={!day_allowed?(day, @min, @max)}
            phx-click="pick"
            phx-value-date={Date.to_iso8601(day)}
            phx-target={@myself}
            class={Helpers.classes(@paperize, day_classes(endpoint?(@range, @target_date, day), day == @today), nil)}
          >
            {day.day}
          </button>
        </span>
      </div>
    </div>

    <div
      :if={@mode == :years}
      class="mt-1 grid max-h-[288px] grid-cols-3 gap-y-2 overflow-y-auto py-2"
    >
      <span :for={year <- years(@view, @min, @max)} class="flex justify-center">
        <button
          type="button"
          aria-selected={to_string(year == @view.year)}
          phx-click="year"
          phx-value-year={year}
          phx-target={@myself}
          class={Helpers.classes(@paperize, year_classes(year == @view.year), nil)}
        >
          {year}
        </button>
      </span>
    </div>
    """
  end

  defp display(nil, _format), do: nil

  defp display({start, finish}, format),
    do: "#{display(start, format)} – #{display(finish || start, format)}"

  defp display(date, nil), do: Date.to_iso8601(date)
  defp display(date, format) when is_function(format, 1), do: format.(date)

  defp range_iso({start, _}, 0), do: Date.to_iso8601(start)
  defp range_iso({_, %Date{} = finish}, 1), do: Date.to_iso8601(finish)
  defp range_iso(_range, _index), do: nil

  defp headline(nil, _months), do: "—"
  defp headline({start, nil}, months), do: "#{short(start, months)} – …"
  defp headline({start, finish}, months), do: "#{short(start, months)} – #{short(finish, months)}"

  defp headline(date, months),
    do: "#{date.day} #{String.slice(Enum.at(months, date.month - 1), 0, 3)} #{date.year}"

  defp short(date, months),
    do: "#{String.slice(Enum.at(months, date.month - 1), 0, 3)} #{date.day}"

  defp endpoint?(false, target, day), do: target == day
  defp endpoint?(true, {start, finish}, day), do: day == start or day == finish
  defp endpoint?(true, _range, _day), do: false

  defp selected_day?(false, target, day), do: target == day
  defp selected_day?(true, range, day), do: endpoint?(true, range, day) or between?(range, day)

  defp between?({start, %Date{} = finish}, day),
    do: Date.compare(day, start) == :gt and Date.compare(day, finish) == :lt

  defp between?(_range, _day), do: false

  # The range band behind the days: full width between the endpoints, and
  # half a cell on the inner side of each endpoint so it meets the circle.
  defp range_band(true, {start, %Date{} = finish}, day) when start != finish do
    cond do
      day == start -> "bg-linear-to-r from-transparent from-50% to-pp-secondary-container to-50%"
      day == finish -> "bg-linear-to-l from-transparent from-50% to-pp-secondary-container to-50%"
      between?({start, finish}, day) -> "bg-pp-secondary-container"
      true -> nil
    end
  end

  defp range_band(_range, _target, _day), do: nil

  @doc false
  # Rows of 7 (nil = blank) for the month of `view`, weeks starting on
  # `first_day` (1 = Monday .. 7 = Sunday).
  def weeks(view, first_day) do
    first = Date.beginning_of_month(view)
    blanks = rem(Date.day_of_week(first) - first_day + 7, 7)
    days = Enum.map(0..(Date.days_in_month(first) - 1), &Date.add(first, &1))

    (List.duplicate(nil, blanks) ++ days)
    |> Enum.chunk_every(7, 7, List.duplicate(nil, 6))
  end

  defp weekday_labels(names, first_day) do
    # `names` is Monday-first.
    Enum.map(0..6, fn i -> Enum.at(names, rem(first_day - 1 + i, 7)) end)
  end

  defp day_allowed?(day, min, max) do
    min = to_date(min)
    max = to_date(max)

    (is_nil(min) or Date.compare(day, min) != :lt) and
      (is_nil(max) or Date.compare(day, max) != :gt)
  end

  defp month_allowed?(month_start, min, max) do
    month_end = Date.end_of_month(month_start)
    min = to_date(min)
    max = to_date(max)

    (is_nil(min) or Date.compare(month_end, min) != :lt) and
      (is_nil(max) or Date.compare(month_start, max) != :gt)
  end

  defp years(view, min, max) do
    lo = (to_date(min) || %{year: view.year - 100}).year
    hi = (to_date(max) || %{year: view.year + 100}).year
    Enum.to_list(lo..hi)
  end

  defp day_classes(selected, today) do
    [
      "relative inline-flex size-10 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full pp-body-large pp-state-layer pp-focus-ring disabled:cursor-default disabled:text-pp-on-surface/38",
      cond do
        selected -> "bg-pp-primary text-pp-on-primary"
        today -> "border border-pp-primary text-pp-primary"
        true -> "text-pp-on-surface"
      end
    ]
  end

  defp year_classes(true),
    do:
      "relative inline-flex h-9 w-[72px] cursor-pointer items-center justify-center overflow-hidden rounded-pp-full bg-pp-primary pp-body-large text-pp-on-primary pp-state-layer pp-focus-ring"

  defp year_classes(false),
    do:
      "relative inline-flex h-9 w-[72px] cursor-pointer items-center justify-center overflow-hidden rounded-pp-full pp-body-large text-pp-on-surface-variant pp-state-layer pp-focus-ring"
end
