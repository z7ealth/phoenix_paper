defmodule PhoenixPaper.Autocomplete do
  @moduledoc """
  A Material Design autocomplete — a text field with a filtered dropdown of
  options.

  Unlike every other PhoenixPaper component, this one needs interactive
  state (the current query, which options are filtered, whether the
  dropdown is open), so it's a `Phoenix.LiveComponent`, not a stateless
  function component, and it only works inside a LiveView (not a plain,
  non-LiveView controller-rendered page). Use it like any other live
  component:

      <.live_component
        module={PhoenixPaper.Autocomplete}
        id="country"
        name="country"
        label="Country"
        options={["Canada", "Mexico", "United States"]}
      />

  Filtering runs entirely server-side via `phx-change`/`phx-debounce` on the
  text input — no client JS beyond what LiveView already ships.

  Every `phx-*` binding in the template needs its *own* `phx-target={@myself}`
  — it isn't inherited from an ancestor element the way `phx-target` on a
  `<form>` might suggest. A `phx-focus="open"` on the `<input>` without one
  routes that event to the parent LiveView instead of this component; if the
  parent has no matching `handle_event/3` clause, the whole LiveView crashes
  and remounts, which looks like nothing happened at all — the dropdown
  never had a chance to render before the reset.
  """
  use Phoenix.LiveComponent

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Shape}

  @impl true
  def update(assigns, socket) do
    options = Enum.map(assigns.options, &normalize_option/1)

    socket =
      socket
      |> assign(assigns)
      |> assign(:options, options)
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:placeholder, fn -> nil end)
      |> assign_new(:paperize, fn -> true end)
      |> assign_new(:shape, fn -> :sm end)
      |> assign_new(:open, fn -> false end)
      |> assign_new(:query, fn -> label_for(options, assigns[:value]) end)
      |> update_filtered()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      data-pp-component="autocomplete"
      class="relative"
      phx-click-away={JS.push("close", target: @myself)}
    >
      <form phx-change="query" phx-target={@myself} onsubmit="event.preventDefault()">
        <div class={Helpers.classes(@paperize, wrapper_classes(@shape), nil)}>
          <input
            type="text"
            autocomplete="off"
            value={@query}
            placeholder={@placeholder}
            phx-focus="open"
            phx-target={@myself}
            phx-debounce="150"
            name="query"
            class={Helpers.classes(@paperize, input_classes(), nil)}
          />
          <span
            :if={@paperize}
            class="pointer-events-none absolute right-3 top-1/2 size-0 -translate-y-1/2 border-x-4 border-t-4 border-x-transparent border-t-pp-outline"
          />
          <label :if={@label} class={Helpers.classes(@paperize, label_classes(), nil)}>{@label}</label>
        </div>
      </form>

      <input type="hidden" name={@name} value={@value} />

      <ul
        :if={@open && @filtered != []}
        class={Helpers.classes(@paperize, list_classes(@shape), nil)}
      >
        <li :for={{opt_label, opt_value} <- @filtered}>
          <button
            type="button"
            phx-click="select"
            phx-value-value={opt_value}
            phx-value-label={opt_label}
            phx-target={@myself}
            class="block w-full cursor-pointer px-3 py-2 text-left text-sm hover:bg-pp-primary/10"
          >
            {opt_label}
          </button>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_event("query", %{"query" => query}, socket) do
    {:noreply, socket |> assign(query: query, open: true) |> update_filtered()}
  end

  def handle_event("open", _params, socket), do: {:noreply, assign(socket, :open, true)}
  def handle_event("close", _params, socket), do: {:noreply, assign(socket, :open, false)}

  def handle_event("select", %{"value" => value, "label" => label}, socket) do
    {:noreply, assign(socket, value: value, query: label, open: false)}
  end

  defp update_filtered(socket) do
    query = String.downcase(socket.assigns.query || "")

    filtered =
      Enum.filter(socket.assigns.options, fn {opt_label, _value} ->
        String.contains?(String.downcase(opt_label), query)
      end)

    assign(socket, :filtered, filtered)
  end

  defp label_for(_options, nil), do: ""

  defp label_for(options, value) do
    case Enum.find(options, fn {_label, opt_value} -> opt_value == value end) do
      {label, _value} -> label
      nil -> ""
    end
  end

  defp normalize_option({label, value}), do: {to_string(label), value}
  defp normalize_option(value), do: {to_string(value), value}

  defp wrapper_classes(shape) do
    [
      "relative border border-pp-outline transition-colors focus-within:border-2 focus-within:border-pp-primary",
      Shape.class(shape)
    ]
  end

  defp input_classes do
    "peer block w-full bg-transparent px-3 pt-7 pb-2 pr-8 text-sm text-pp-on-surface outline-none"
  end

  defp label_classes do
    "pointer-events-none absolute left-3 top-2 text-xs text-pp-outline"
  end

  defp list_classes(shape) do
    [
      "absolute z-10 mt-1 max-h-56 w-full overflow-auto border border-pp-outline bg-pp-surface",
      Shape.class(shape),
      "pp-elevation-4"
    ]
  end
end
