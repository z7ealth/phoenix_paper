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
          aria-label="Move selected right"
          phx-click="move_right"
          phx-target={@myself}
          disabled={Enum.all?(@left, &(&1 not in @checked))}
          class={Helpers.classes(@paperize, "relative inline-flex size-10 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full border border-pp-outline-variant text-pp-on-surface-variant pp-state-layer pp-focus-ring pp-motion-spatial-fast active:rounded-pp-sm disabled:cursor-default disabled:border-pp-on-surface/12 disabled:text-pp-on-surface/38", nil)}
        >
          <PhoenixPaper.Icon.pp_icon name="hero-chevron-right" size="sm" />
        </button>
        <button
          type="button"
          aria-label="Move selected left"
          phx-click="move_left"
          phx-target={@myself}
          disabled={Enum.all?(@right, &(&1 not in @checked))}
          class={Helpers.classes(@paperize, "relative inline-flex size-10 cursor-pointer items-center justify-center overflow-hidden rounded-pp-full border border-pp-outline-variant text-pp-on-surface-variant pp-state-layer pp-focus-ring pp-motion-spatial-fast active:rounded-pp-sm disabled:cursor-default disabled:border-pp-on-surface/12 disabled:text-pp-on-surface/38", nil)}
        >
          <PhoenixPaper.Icon.pp_icon name="hero-chevron-left" size="sm" />
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
    <div class={Helpers.classes(@paperize, "flex w-56 flex-col overflow-hidden rounded-pp-md border border-pp-outline-variant", nil)}>
      <div class={Helpers.classes(
        @paperize,
        "border-b border-pp-outline-variant bg-pp-surface-container px-4 py-3 pp-title-small text-pp-on-surface-variant",
        nil
      )}>
        {@label} ({length(@items)})
      </div>
      <ul class="max-h-56 overflow-auto">
        <li :for={item <- @items}>
          <label class={Helpers.classes(
            @paperize,
            "flex min-h-12 cursor-pointer items-center gap-4 px-4 py-2 pp-body-large hover:bg-pp-on-surface/8",
            nil
          )}>
            <input
              type="checkbox"
              checked={item in @checked}
              phx-click="toggle"
              phx-value-item={item}
              phx-target={@target}
              class="size-[18px] cursor-pointer accent-pp-primary"
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
