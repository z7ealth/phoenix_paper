defmodule PhoenixPaper.Autocomplete do
  @moduledoc """
  A text field that suggests options as you type (an autocomplete), as a
  `Phoenix.LiveComponent` — so it works inside a LiveView only, like
  `PhoenixPaper.DatePicker`.

      <.live_component
        module={PhoenixPaper.Autocomplete}
        id="country"
        field={@form[:country]}
        label="Country"
        options={[{"Canada", "ca"}, {"Mexico", "mx"}, {"United States", "us"}]}
      />

  MD3 has no autocomplete component, so this is a composite of two MD3
  parts: an MD3 text field (`pp_text_field`, `outlined` or `filled`, with
  its label, supporting text and errors) and, under it, the MD3 menu
  surface (`surface-container`, 16dp corners, level-2 shadow) holding the
  matching options as menu items, anchored to the field box through the
  text field's `:menu` slot. The picked option takes the menu's
  selected color.

  `options` are plain values or `{label, value}` tuples. Typing filters
  them by label (case- and accent-insensitive) on the server, debounced.

  ## Forms

  `value` (or `field=`) is the selected option's value. It's submitted
  from a hidden input under `name`, and each pick dispatches an `input`
  event from that input, so the surrounding form's `phx-change` runs as
  for a native input (the same mechanism as `PhoenixPaper.DatePicker`).
  Outside a form, `on_change` (a `value | nil -> any` function, run in the
  LiveView process) is called on every change. Clearing the text clears
  the value.

  The text box itself is detached from any surrounding form (its `form`
  attribute names an element that doesn't exist, and it has no `name`):
  it's never submitted and never triggers that form's `phx-change`; only
  the hidden input carries the value. It sends `phx-keyup` instead of
  `phx-change`, which would need a form of its own, and a nested `<form>`
  inside the caller's form is invalid HTML.

  ## Multiple values (input chips)

  `multiple` lets the user pick several options. Each pick becomes an MD3
  input chip (`pp_chip variant="input"`, with its remove control) inside
  the text field, before the text box, as MD3 shows them (the field's
  `:chips` slot: the row wraps, and the label stays raised while there
  are chips). The list stays open for the next pick, picking a selected
  option again removes it, and Backspace in an empty text box removes the
  last chip.

      <.live_component
        module={PhoenixPaper.Autocomplete}
        id="tags"
        field={@form[:tags]}
        label="Tags"
        options={@all_tags}
        multiple
      />

  `value` is then a list. It's submitted as `name[]` (one hidden input
  per value), plus one empty `name[]` value so that removing every chip
  still submits the field — filter out the `""` when you cast it (e.g.
  `Enum.reject(tags, &(&1 == ""))`). `on_change` receives the list.

  ## Keyboard and accessibility

  The field is an ARIA `combobox` controlling a `listbox` of `option`s.
  Arrow Down/Up move focus through the options, Enter on an option picks
  it (Enter in the text box doesn't submit the form), Escape or a click
  outside closes the list. With `multiple` the listbox is
  `aria-multiselectable`.

  ## Attributes

  `options` (required), `name`, `value`, `field`, `label`, `variant`
  (`outlined`/`filled`), `supporting_text`, `errors`, `disabled`,
  `on_change`, `multiple`, `no_results_label` (default `"No results"`),
  `remove_label` (default `"Remove"`, the chips' remove control),
  `paperize`, `class`.

  ## Migrating from 0.4

  The field is now a real `pp_text_field` and the list the MD3 menu
  surface. `placeholder` and `shape` are gone (MD3 text fields use their
  label, and fix their shape); `field=`, `variant`, `supporting_text`,
  `errors`, `disabled` and `on_change` are new, and a pick now reaches the
  form's `phx-change`.
  """
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Menu}
  import PhoenixPaper.Chip, only: [pp_chip: 1]
  import PhoenixPaper.Icon, only: [pp_icon: 1]
  import PhoenixPaper.TextField, only: [pp_text_field: 1]

  @defaults [
    name: nil,
    value: nil,
    field: nil,
    label: nil,
    variant: "outlined",
    supporting_text: nil,
    errors: [],
    disabled: false,
    on_change: nil,
    multiple: false,
    no_results_label: "No results",
    remove_label: "Remove",
    paperize: true,
    class: nil
  ]

  # Arrow keys move focus through the options; Enter in the text box is
  # swallowed so it doesn't submit the surrounding form; Backspace in an
  # empty text box clicks the last chip's remove control. Focus moves and
  # clicks can't be undone by a LiveView patch, unlike attribute changes.
  @keyboard_js """
  var k=event.key;\
  if(k==='Enter'&&event.target.tagName==='INPUT'){event.preventDefault();return;}\
  if(k==='Backspace'&&event.target.tagName==='INPUT'&&event.target.value===''){\
  var d=this.querySelectorAll('[data-pp-component=chip-delete]');\
  if(d.length){d[d.length-1].click();}return;}\
  if(k!=='ArrowDown'&&k!=='ArrowUp'){return;}\
  var o=Array.prototype.slice.call(this.querySelectorAll('[role=option]'));\
  if(!o.length){return;}\
  event.preventDefault();\
  var i=o.indexOf(document.activeElement);\
  i=k==='ArrowDown'?(i+1)%o.length:(i<=0?o.length-1:i-1);\
  o[i].focus();\
  """

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       open: false,
       query: "",
       filtered: [],
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
      |> assign(:options, Enum.map(assigns[:options] || [], &normalize_option/1))
      |> apply_field(assigns)
      |> seed()
      |> filter()

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

  defp seed(%{assigns: %{multiple: true}} = socket) do
    assign(socket,
      value: socket.assigns.value |> List.wrap() |> Enum.reject(&(&1 in [nil, ""])),
      query: "",
      external_value: socket.assigns.value
    )
  end

  defp seed(socket) do
    assign(socket,
      query: label_for(socket.assigns.options, socket.assigns.value),
      external_value: socket.assigns.value
    )
  end

  @impl true
  def handle_event("open", _params, %{assigns: %{disabled: true}} = socket),
    do: {:noreply, socket}

  def handle_event("open", _params, socket),
    do: {:noreply, socket |> assign(open: true) |> filter()}

  def handle_event("close", _params, socket), do: {:noreply, assign(socket, open: false)}

  def handle_event("query", %{"value" => ""}, %{assigns: %{multiple: true}} = socket),
    do: {:noreply, socket |> assign(query: "", open: true) |> filter()}

  def handle_event("query", %{"value" => ""}, socket) do
    socket = assign(socket, query: "", open: true)
    socket = if is_nil(socket.assigns.value), do: socket, else: commit(socket, nil)
    {:noreply, filter(socket)}
  end

  def handle_event("query", %{"value" => query}, socket),
    do: {:noreply, socket |> assign(query: query, open: true) |> filter()}

  def handle_event("query", _params, socket), do: {:noreply, socket}

  def handle_event("pick", %{"value" => picked}, %{assigns: %{multiple: true}} = socket) do
    case find_option(socket.assigns.options, picked) do
      {_label, value} ->
        values = socket.assigns.value

        values =
          if Enum.any?(values, &(to_string(&1) == picked)),
            do: Enum.reject(values, &(to_string(&1) == picked)),
            else: values ++ [value]

        {:noreply, socket |> assign(query: "") |> commit(values) |> filter()}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("pick", %{"value" => picked}, socket) do
    case find_option(socket.assigns.options, picked) do
      {label, value} ->
        {:noreply, socket |> assign(query: label, open: false) |> commit(value)}

      nil ->
        {:noreply, socket}
    end
  end

  def handle_event("remove", %{"value" => removed}, socket) do
    values = Enum.reject(socket.assigns.value, &(to_string(&1) == removed))
    {:noreply, commit(socket, values)}
  end

  defp find_option(options, picked),
    do: Enum.find(options, fn {_label, value} -> to_string(value) == picked end)

  defp selected?(%{multiple: true, value: values}, value),
    do: Enum.any?(values, &(to_string(&1) == to_string(value)))

  defp selected?(%{value: current}, value), do: to_string(current) == to_string(value)

  defp commit(socket, value) do
    if on_change = socket.assigns.on_change, do: on_change.(value)
    assign(socket, value: value, change_count: socket.assigns.change_count + 1)
  end

  defp filter(socket) do
    query = fold(socket.assigns.query)

    filtered =
      if query == "" or
           (!socket.assigns.multiple and
              label_for(socket.assigns.options, socket.assigns.value) == socket.assigns.query) do
        socket.assigns.options
      else
        Enum.filter(socket.assigns.options, fn {label, _value} ->
          String.contains?(fold(label), query)
        end)
      end

    assign(socket, :filtered, filtered)
  end

  # Case- and accent-insensitive: NFD splits "é" into "e" + a combining
  # mark, which the regex drops.
  defp fold(text) do
    text
    |> to_string()
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
  end

  defp label_for(_options, nil), do: ""

  defp label_for(options, value) do
    case Enum.find(options, fn {_label, opt} -> to_string(opt) == to_string(value) end) do
      {label, _value} -> label
      nil -> ""
    end
  end

  defp normalize_option({label, value}), do: {to_string(label), value}
  defp normalize_option(value), do: {to_string(value), value}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :keyboard_js, @keyboard_js)

    ~H"""
    <div
      id={@id}
      data-pp-component="autocomplete"
      class={Helpers.classes(@paperize, "relative flex flex-col", @class)}
      phx-click-away={@open && JS.push("close", target: @myself)}
      phx-window-keydown={@open && "close"}
      phx-key="escape"
      phx-target={@myself}
      onkeydown={@keyboard_js}
    >
      <input :if={!@multiple} type="hidden" id={"#{@id}-value"} name={@name} value={@value} />
      <input :if={@multiple} type="hidden" id={"#{@id}-value"} name={@name && @name <> "[]"} value="" />
      <input
        :for={value <- (@multiple && @value) || []}
        type="hidden"
        name={@name && @name <> "[]"}
        value={value}
      />
      <span
        :if={@change_count > 0}
        id={"#{@id}-changed-#{@change_count}"}
        hidden
        phx-mounted={JS.dispatch("input", to: "##{@id}-value")}
      />

      <.pp_text_field
        id={"#{@id}-query"}
        label={@label}
        value={@query}
        variant={@variant}
        disabled={@disabled}
        errors={@errors}
        supporting_text={@supporting_text}
        paperize={@paperize}
        form={"#{@id}-detached"}
        autocomplete="off"
        role="combobox"
        aria-autocomplete="list"
        aria-expanded={to_string(@open)}
        aria-controls={"#{@id}-listbox"}
        phx-focus="open"
        phx-keyup="query"
        phx-debounce="150"
        phx-target={@myself}
      >
        <:end_adornment>
          <.pp_icon
            name="hero-chevron-down"
            class={["pp-motion-spatial-fast", @open && "rotate-180"]}
          />
        </:end_adornment>
        <:chips :if={@multiple and @value != []}>
          <.pp_chip
            :for={value <- @value}
            variant="input"
            deletable
            delete_label={"#{@remove_label} #{label_for(@options, value)}"}
            on_delete={JS.push("remove", value: %{value: to_string(value)}, target: @myself)}
            disabled={@disabled}
            paperize={@paperize}
          >
            {label_for(@options, value)}
          </.pp_chip>
        </:chips>
        <:menu>
        <div
          :if={@open}
          id={"#{@id}-listbox"}
          role="listbox"
          aria-multiselectable={@multiple && "true"}
          aria-label={@label}
          class={Helpers.classes(@paperize, panel_classes(), nil)}
        >
          <button
            :for={{label, value} <- @filtered}
            type="button"
            role="option"
            aria-selected={to_string(selected?(assigns, value))}
            phx-click={
              JS.push("pick", value: %{value: to_string(value)}, target: @myself)
              |> JS.focus(to: "##{@id}-query")
            }
            class={Helpers.classes(@paperize, Menu.item_classes(selected?(assigns, value)), nil)}
          >
            <span class="min-w-0 flex-1 truncate text-start">{label}</span>
          </button>
          <div
            :if={@filtered == []}
            class={Helpers.classes(@paperize, "px-3 py-3 pp-body-medium text-pp-on-surface-variant", nil)}
          >
            {@no_results_label}
          </div>
        </div>
        </:menu>
      </.pp_text_field>

    </div>
    """
  end

  # The MD3 menu surface, in the text field's `:menu` slot: positioned
  # against the field box (not the supporting text), right under it however
  # tall the chips make it, and as wide as the field.
  defp panel_classes do
    "absolute inset-x-0 top-full z-40 mt-1 flex max-h-72 flex-col gap-0.5 overflow-y-auto rounded-pp-lg bg-pp-surface-container p-1 text-pp-on-surface pp-elevation-2"
  end
end
