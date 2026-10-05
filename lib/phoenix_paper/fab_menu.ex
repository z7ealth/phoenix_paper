defmodule PhoenixPaper.FabMenu do
  @moduledoc """
  An M3 Expressive FAB menu (`pp_fab_menu/1`): a FAB that opens a short
  stack of related actions. It replaces 0.3's `SpeedDial` (MD3 retired the
  speed dial in favor of this).

      <.pp_fab_menu id="create" label="Create" position="fixed" class="bottom-4 right-4">
        <:item icon="hero-document" label="Document" navigate={~p"/docs/new"} />
        <:item icon="hero-table-cells" label="Spreadsheet" on_click={JS.push("new_sheet")} />
        <:item icon="hero-photo" label="Photo" on_click={JS.push("upload")} />
      </.pp_fab_menu>

  Tapping the FAB morphs it into a round close button (the Expressive
  spatial spring) and the items rise above it as labeled pills. Tapping
  the close button, anything outside the menu, or pressing Escape closes
  it.

  ## Color

  `color` picks the family, per the MD3 spec: `primary` (default) gives a
  `primary-container` FAB, a `primary` close button and
  `primary-container` items; likewise `secondary` and `tertiary`.

  ## How it works

  CSS only, like `NavigationRail`/`Accordion`: a visually hidden checkbox is
  the open state, the FAB is its `<label>`, and everything that changes
  when open reacts with `peer-checked:`. Click-away is a transparent
  full-screen `<label>` for the same checkbox, rendered only while open,
  under the menu. Escape is a two-line inline `onkeydown` on the root. It
  works on controller-rendered pages too — no LiveView needed.

  Items link (`href`/`navigate`/`patch`) or fire `on_click` (a `JS`, e.g.
  `JS.push(...)`). Following an item doesn't need to close the menu
  explicitly: navigation replaces the page, and a `JS.push` item can add
  `JS.dispatch("click", to: "#<id>-scrim")` to close it.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Elevation, Helpers, Icon, Ripple}

  attr(:id, :string, required: true)
  attr(:label, :string, required: true, doc: "accessible name of the FAB")
  attr(:icon, :string, default: "hero-plus", doc: "the FAB's icon")
  attr(:close_icon, :string, default: "hero-x-mark", doc: "the close button's icon")
  attr(:color, :string, default: "primary", values: ~w(primary secondary tertiary))
  attr(:size, :string, default: "default", values: ~w(default medium large))
  attr(:default_open, :boolean, default: false)
  attr(:ripple, :boolean, default: true)

  attr(:position, :string,
    default: "relative",
    values: ~w(relative fixed absolute sticky),
    doc: "the root's CSS position; offsets go in class"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item, required: true, doc: "a menu action" do
    attr(:label, :string, required: true)
    attr(:icon, :string, doc: "a hero-* icon name")
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:on_click, :any, doc: "a Phoenix.LiveView.JS (or event name) for phx-click")
  end

  @escape_js "if(event.key==='Escape'){var c=this.querySelector(':scope>input[type=checkbox]');if(c&&c.checked){c.checked=false;c.focus();}}"

  @doc "Renders a FAB menu. See the module doc."
  def pp_fab_menu(assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize)
      |> assign(:escape_js, @escape_js)
      |> assign(:items, Enum.with_index(assigns.item))

    ~H"""
    <div
      id={@id}
      data-pp-component="fab-menu"
      class={["inline-flex flex-col items-end", position_class(@position), @class]}
      onkeydown={@escape_js}
      {@rest}
    >
      <input
        type="checkbox"
        id={"#{@id}-toggle"}
        checked={@default_open}
        aria-label={@label}
        aria-haspopup="menu"
        aria-controls={"#{@id}-items"}
        class="peer sr-only"
      />
      <label
        for={"#{@id}-toggle"}
        id={"#{@id}-scrim"}
        aria-hidden="true"
        class="fixed inset-0 z-0 hidden cursor-default peer-checked:block"
      />
      <ul
        id={"#{@id}-items"}
        role="menu"
        class={[
          "absolute bottom-full right-0 z-10 mb-2 flex flex-col items-end gap-1",
          "invisible peer-checked:visible"
        ]}
      >
        <li
          :for={{item, index} <- Enum.reverse(@items)}
          role="none"
          class={[
            "translate-y-4 scale-90 opacity-0 pp-motion-spatial-default",
            "[[aria-controls]:checked~ul_&]:translate-y-0 [[aria-controls]:checked~ul_&]:scale-100 [[aria-controls]:checked~ul_&]:opacity-100",
            delay_class(length(@items) - 1 - index)
          ]}
        >
          <.fab_menu_item item={item} color={@color} ripple?={@ripple?} paperize={@paperize} />
        </li>
      </ul>
      <label
        for={"#{@id}-toggle"}
        onclick={Ripple.on_click(@ripple?)}
        class={Helpers.classes(@paperize, fab_classes(@color, @size, @ripple?), nil)}
      >
        <Icon.pp_icon
          name={@icon}
          size="none"
          class="size-[1em] pp-motion-spatial-fast [:checked~label>&]:rotate-90 [:checked~label>&]:scale-0 [:checked~label>&]:opacity-0"
        />
        <Icon.pp_icon
          name={@close_icon}
          size="none"
          class="absolute size-6 -rotate-90 scale-0 opacity-0 pp-motion-spatial-fast [:checked~label>&]:rotate-0 [:checked~label>&]:scale-100 [:checked~label>&]:opacity-100"
        />
      </label>
    </div>
    """
  end

  attr(:item, :any, required: true)
  attr(:color, :string, required: true)
  attr(:ripple?, :boolean, required: true)
  attr(:paperize, :boolean, required: true)

  defp fab_menu_item(assigns) do
    linked? =
      assigns.item[:href] not in [nil, false] or assigns.item[:navigate] not in [nil, false] or
        assigns.item[:patch] not in [nil, false]

    assigns = assign(assigns, :linked?, linked?)

    ~H"""
    <.link
      :if={@linked?}
      href={@item[:href]}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      role="menuitem"
      onclick={Ripple.on_click(@ripple?)}
      data-pp-component="fab-menu-item"
      class={Helpers.classes(@paperize, item_classes(@color), nil)}
    >
      <Icon.pp_icon :if={@item[:icon]} name={@item[:icon]} />
      {@item.label}
    </.link>
    <button
      :if={!@linked?}
      type="button"
      role="menuitem"
      phx-click={@item[:on_click]}
      onclick={Ripple.on_click(@ripple?)}
      data-pp-component="fab-menu-item"
      class={Helpers.classes(@paperize, item_classes(@color), nil)}
    >
      <Icon.pp_icon :if={@item[:icon]} name={@item[:icon]} />
      {@item.label}
    </button>
    """
  end

  # Positioning plumbing — unconditional, like Menu's anchor wrapper.
  defp position_class("relative"), do: "relative"
  defp position_class("fixed"), do: "fixed"
  defp position_class("absolute"), do: "absolute"
  defp position_class("sticky"), do: "sticky"

  # Items rise one after another, nearest the FAB first.
  defp delay_class(0), do: "delay-0"
  defp delay_class(1), do: "delay-[30ms]"
  defp delay_class(2), do: "delay-[60ms]"
  defp delay_class(3), do: "delay-[90ms]"
  defp delay_class(4), do: "delay-[120ms]"
  defp delay_class(_index), do: "delay-[150ms]"

  defp fab_classes(color, size, ripple?) do
    [
      "relative z-10 inline-flex shrink-0 cursor-pointer select-none items-center justify-center pp-state-layer pp-motion-spatial-fast",
      "peer-focus-visible:outline-3 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-pp-secondary peer-focus-visible:outline-solid",
      fab_size(size),
      fab_color(color),
      Elevation.class(3),
      Elevation.hover_class(4),
      ripple? && "overflow-hidden"
    ]
  end

  # Open: every size collapses to the 56dp round close button.
  defp fab_size("default"),
    do: "size-14 rounded-pp-lg text-[24px] peer-checked:rounded-[28px]"

  defp fab_size("medium"),
    do:
      "size-20 rounded-pp-lg-increased text-[28px] peer-checked:size-14 peer-checked:rounded-[28px]"

  defp fab_size("large"),
    do: "size-24 rounded-pp-xl text-[36px] peer-checked:size-14 peer-checked:rounded-[28px]"

  defp fab_color("primary"),
    do:
      "bg-pp-primary-container text-pp-on-primary-container peer-checked:bg-pp-primary peer-checked:text-pp-on-primary"

  defp fab_color("secondary"),
    do:
      "bg-pp-secondary-container text-pp-on-secondary-container peer-checked:bg-pp-secondary peer-checked:text-pp-on-secondary"

  defp fab_color("tertiary"),
    do:
      "bg-pp-tertiary-container text-pp-on-tertiary-container peer-checked:bg-pp-tertiary peer-checked:text-pp-on-tertiary"

  defp item_classes(color) do
    [
      "relative inline-flex h-14 cursor-pointer select-none items-center gap-2 overflow-hidden whitespace-nowrap rounded-[28px] px-6 pp-title-medium pp-state-layer pp-focus-ring pp-motion-spatial-fast active:rounded-pp-lg",
      item_color(color)
    ]
  end

  defp item_color("primary"), do: "bg-pp-primary-container text-pp-on-primary-container"
  defp item_color("secondary"), do: "bg-pp-secondary-container text-pp-on-secondary-container"
  defp item_color("tertiary"), do: "bg-pp-tertiary-container text-pp-on-tertiary-container"
end
