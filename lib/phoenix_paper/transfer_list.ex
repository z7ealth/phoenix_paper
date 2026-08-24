defmodule PhoenixPaper.TransferList do
  @moduledoc """
  A Material Design transfer list — two list boxes with buttons to move
  checked items between them.

  Like `PhoenixPaper.Autocomplete`, this needs interactive state (which list
  each item currently lives in, which are checked), so it's a
  `Phoenix.LiveComponent`, not a stateless function component. It manages
  that state entirely on its own:

      <.live_component
        module={PhoenixPaper.TransferList}
        id="permissions"
        items={["Read", "Write", "Admin"]}
      />

  There is no `on_change` callback in this first version — the split lives
  only in the component's own state. A form that needs the current `right`
  list server-side isn't supported yet; ask if you need it and it'll be
  added (e.g. as a hidden input per item, or a message sent to the parent
  LiveView on every move).
  """
  use Phoenix.LiveComponent

  alias PhoenixPaper.Helpers

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:paperize, fn -> true end)
      |> assign_new(:left_label, fn -> "Available" end)
      |> assign_new(:right_label, fn -> "Selected" end)
      |> assign_new(:right, fn -> [] end)
      |> assign_new(:checked, fn -> MapSet.new() end)
      |> assign_new(:left, fn -> assigns[:items] || [] end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-pp-component="transfer-list" class="flex items-center gap-4">
      <.list label={@left_label} items={@left} checked={@checked} target={@myself} paperize={@paperize} />

      <div class="flex flex-col gap-2">
        <button
          type="button"
          phx-click="move_right"
          phx-target={@myself}
          disabled={Enum.all?(@left, &(&1 not in @checked))}
          class={Helpers.classes(@paperize, "cursor-pointer border border-pp-outline px-3 py-1 text-sm disabled:cursor-not-allowed disabled:opacity-40", nil)}
        >
          {"›"}
        </button>
        <button
          type="button"
          phx-click="move_left"
          phx-target={@myself}
          disabled={Enum.all?(@right, &(&1 not in @checked))}
          class={Helpers.classes(@paperize, "cursor-pointer border border-pp-outline px-3 py-1 text-sm disabled:cursor-not-allowed disabled:opacity-40", nil)}
        >
          {"‹"}
        </button>
      </div>

      <.list label={@right_label} items={@right} checked={@checked} target={@myself} paperize={@paperize} />
    </div>
    """
  end

  attr(:label, :string, required: true)
  attr(:items, :list, required: true)
  attr(:checked, :any, required: true)
  attr(:target, :any, required: true)
  attr(:paperize, :boolean, required: true)

  defp list(assigns) do
    ~H"""
    <div class={Helpers.classes(@paperize, "flex w-48 flex-col border border-pp-outline", nil)}>
      <div class={Helpers.classes(
        @paperize,
        "border-b border-pp-outline bg-pp-surface-variant px-3 py-2 text-xs font-medium uppercase",
        nil
      )}>
        {@label} ({length(@items)})
      </div>
      <ul class="max-h-56 overflow-auto">
        <li :for={item <- @items}>
          <label class={Helpers.classes(
            @paperize,
            "flex cursor-pointer items-center gap-2 px-3 py-2 text-sm hover:bg-pp-primary/10",
            nil
          )}>
            <input
              type="checkbox"
              checked={item in @checked}
              phx-click="toggle"
              phx-value-item={item}
              phx-target={@target}
              class="cursor-pointer"
            />
            {item}
          </label>
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_event("toggle", %{"item" => item}, socket) do
    checked = socket.assigns.checked

    checked =
      if item in checked, do: MapSet.delete(checked, item), else: MapSet.put(checked, item)

    {:noreply, assign(socket, :checked, checked)}
  end

  def handle_event("move_right", _params, socket) do
    %{left: left, right: right, checked: checked} = socket.assigns
    moving = Enum.filter(left, &(&1 in checked))

    {:noreply,
     assign(socket, left: left -- moving, right: right ++ moving, checked: MapSet.new())}
  end

  def handle_event("move_left", _params, socket) do
    %{left: left, right: right, checked: checked} = socket.assigns
    moving = Enum.filter(right, &(&1 in checked))

    {:noreply,
     assign(socket, left: left ++ moving, right: right -- moving, checked: MapSet.new())}
  end
end
