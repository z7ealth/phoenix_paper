defmodule PhoenixPaper.Menu do
  @moduledoc """
  An MD3 menu (`pp_menu/1`, `pp_menu_item/1`) with the M3 Expressive menu
  shape and colors — a trigger that opens a short anchored list of
  actions (an overflow menu, a profile menu).

      <.pp_menu id="more" trigger_icon="hero-ellipsis-vertical" trigger_label="More options">
        <.pp_menu_item icon="hero-pencil" trailing_text="⌘E" phx-click="edit">Edit</.pp_menu_item>
        <.pp_menu_item icon="hero-document-duplicate" phx-click="duplicate">Duplicate</.pp_menu_item>
        <.pp_divider class="my-1" />
        <.pp_menu_item icon="hero-trash" navigate={~p"/trash"}>Move to trash</.pp_menu_item>
      </.pp_menu>

  ## Trigger

  Either an icon button — `trigger_icon` (a `hero-*` name) plus
  `trigger_label` (its accessible name) — or a common button whose label is
  the `:trigger` slot. `trigger_variant` is passed through
  (`standard`/`filled`/`tonal`/`outlined` for icon triggers,
  `filled`/`tonal`/`elevated`/`outlined`/`text` for button triggers;
  defaults `standard` and `text`); `"none"` renders a bare `<button>`
  holding the `:trigger` slot. `trigger_color` and `trigger_class` pass
  through too. The trigger carries `aria-haspopup`/`aria-expanded`/
  `aria-controls` and toggles the menu.

  ## Panel and items

  The panel is `surface-container` (or `tertiary-container` with
  `color="vibrant"`, Expressive), level-2 shadow, `lg` corners and 4dp of
  inner padding. `pp_menu_item/1` is a 48dp row: optional leading `icon`,
  the label, optional `supporting_text` under it and `trailing_text` (a
  shortcut) or a `:trailing` slot. `selected` gives it the Expressive
  selected look (`secondary-container`, or `tertiary` on vibrant) and
  `aria-checked`; `disabled` dims it. Items link with `href`/`navigate`/
  `patch`, or are buttons firing whatever `phx-click` you give them. Any
  other content works in the panel too (`pp_divider`, a
  `pp_typography variant="title-small"` for a group heading).

  ## Submenus

  `pp_submenu/1` is a cascading submenu: an item with a trailing chevron
  whose panel opens beside it (`side="end"`, default, or `"start"` near
  the right edge — there's no automatic flipping).

      <.pp_menu id="m" trigger_icon="hero-ellipsis-vertical" trigger_label="More">
        <.pp_menu_item phx-click="copy">Copy</.pp_menu_item>
        <.pp_submenu id="m-share" label="Share" icon="hero-share">
          <.pp_menu_item phx-click="share_email">Email</.pp_menu_item>
          <.pp_menu_item phx-click="share_link">Copy link</.pp_menu_item>
        </.pp_submenu>
      </.pp_menu>

  It opens on hover and on keyboard focus (CSS `:hover`/`:focus-within` —
  Tab from the trigger walks into it). Clicking the trigger sets its
  `aria-expanded` and moves focus into the submenu (`JS.set_attribute` +
  `JS.focus_first`; the panel shows off the attribute in CSS), which is
  how it opens on touch and in Safari. The trigger's own `phx-click` also
  keeps the parent menu open: LiveView runs only the nearest `phx-click`,
  so the panel's close-on-click never sees it. Picking an item inside
  closes the whole menu as usual, and `close/2` collapses nested
  submenus.

  ## Behavior

  `Phoenix.LiveView.JS` + `phx-click-away`, the `Dialog` mechanism: the
  trigger toggles the panel, clicking outside or pressing Escape closes
  it, and clicking any item closes it by bubbling up to the panel's own
  `phx-click`. It needs the LiveView JS client on the page.

  Positioning is plain CSS (`absolute` against the menu's `relative`
  wrapper): `anchor` (`bottom-start`/`bottom-end`/`top-start`/`top-end`)
  is where it opens. With the PhoenixPaper JS hook (see
  `PhoenixPaper.Helpers.hook/1`) the menu and its submenus **flip** to the
  other side when they'd overflow the viewport — the hook measures the
  panel as it opens and sets `data-pp-flip`, which `phoenix_paper.css`
  styles. Without the hook, pick an `anchor`/`side` that fits.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Icon}

  import PhoenixPaper.Button, only: [pp_button: 1]
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]

  attr(:id, :string, required: true)

  attr(:anchor, :string,
    default: "bottom-start",
    values: ~w(bottom-start bottom-end top-start top-end)
  )

  attr(:color, :string, default: "standard", values: ~w(standard vibrant))
  attr(:trigger_icon, :string, default: nil, doc: "renders an icon-button trigger")
  attr(:trigger_label, :string, default: nil, doc: "the icon trigger's accessible name")

  attr(:trigger_variant, :string,
    default: nil,
    values: [nil | ~w(standard filled tonal elevated outlined text none)],
    doc: "variant of the trigger button; none = bare button"
  )

  attr(:trigger_color, :string, default: nil, doc: "color of the trigger button")
  attr(:trigger_class, :any, default: nil)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger, doc: "the trigger button's label (button and bare triggers)")
  slot(:inner_block, required: true, doc: "pp_menu_item/1s, dividers, ...")

  @doc "Renders a menu trigger and its panel. See the module doc."
  def pp_menu(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={Helpers.hook(@id)}
      class="relative inline-block"
      data-pp-component="menu"
    >
      <.pp_icon_button
        :if={@trigger_icon}
        id={"#{@id}-trigger"}
        icon={@trigger_icon}
        label={@trigger_label || "Menu"}
        variant={icon_variant(@trigger_variant)}
        color={@trigger_color}
        paperize={@paperize}
        class={@trigger_class}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle(@id)}
      />
      <button
        :if={!@trigger_icon && @trigger_variant == "none"}
        type="button"
        id={"#{@id}-trigger"}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle(@id)}
        class={["cursor-pointer", @trigger_class]}
      >
        {render_slot(@trigger)}
      </button>
      <.pp_button
        :if={!@trigger_icon && @trigger_variant != "none"}
        id={"#{@id}-trigger"}
        variant={button_variant(@trigger_variant)}
        color={@trigger_color}
        paperize={@paperize}
        class={@trigger_class}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={toggle(@id)}
      >
        {render_slot(@trigger)}
        <:end_icon><Icon.pp_icon name="hero-chevron-down" size="sm" /></:end_icon>
      </.pp_button>
      <div
        id={"#{@id}-panel"}
        phx-click-away={close(@id)}
        phx-window-keydown={close(@id)}
        phx-key="escape"
        phx-click={close(@id)}
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        data-pp-component="menu-panel"
        data-pp-color={@color}
        class={[
          "group/menu absolute z-40 hidden",
          anchor_classes(@anchor),
          Helpers.classes(@paperize, panel_classes(@color), @class)
        ]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:icon, :string, default: nil, doc: "a leading hero-* icon")
  attr(:supporting_text, :string, default: nil)
  attr(:trailing_text, :string, default: nil, doc: "e.g. a keyboard shortcut")
  attr(:selected, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(method download target rel replace value name))

  slot(:trailing, doc: "custom trailing content, instead of trailing_text")
  slot(:inner_block, required: true, doc: "the item label")

  @doc "A row in a `pp_menu/1`. See the module doc."
  def pp_menu_item(assigns) do
    linked? =
      assigns.href not in [nil, false] or assigns.navigate not in [nil, false] or
        assigns.patch not in [nil, false]

    assigns = assign(assigns, :linked?, linked?)

    ~H"""
    <.link
      :if={@linked?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      role="menuitem"
      aria-disabled={@disabled && "true"}
      aria-current={@selected && "page"}
      data-pp-component="menu-item"
      class={Helpers.classes(@paperize, item_classes(@selected), @class)}
      {@rest}
    >
      {menu_item_content(assigns)}
    </.link>
    <button
      :if={!@linked?}
      type="button"
      role={if @selected, do: "menuitemradio", else: "menuitem"}
      aria-checked={@selected && "true"}
      disabled={@disabled}
      data-pp-component="menu-item"
      class={Helpers.classes(@paperize, item_classes(@selected), @class)}
      {@rest}
    >
      {menu_item_content(assigns)}
    </button>
    """
  end

  defp menu_item_content(assigns) do
    ~H"""
    <Icon.pp_icon :if={@icon} name={@icon} class="shrink-0 opacity-80" />
    <span class="flex min-w-0 flex-1 flex-col text-start">
      <span class="truncate">{render_slot(@inner_block)}</span>
      <span :if={@supporting_text} class="truncate pp-body-small opacity-80">
        {@supporting_text}
      </span>
    </span>
    <span :if={@trailing_text} class="shrink-0 pp-label-large opacity-80">{@trailing_text}</span>
    {render_slot(@trailing)}
    """
  end

  attr(:id, :string, required: true)
  attr(:label, :string, required: true, doc: "the submenu trigger's text")
  attr(:icon, :string, default: nil, doc: "a leading hero-* icon")
  attr(:side, :string, default: "end", values: ~w(end start), doc: "which side it opens on")
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  slot(:inner_block, required: true, doc: "the submenu's pp_menu_item/1s")

  @doc """
  A cascading submenu inside a `pp_menu/1`: a menu item with a trailing
  chevron that opens a second panel beside it. See the module doc.
  """
  def pp_submenu(assigns) do
    ~H"""
    <div data-pp-component="submenu" class="group/sub relative">
      <button
        type="button"
        id={"#{@id}-trigger"}
        role="menuitem"
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        disabled={@disabled}
        phx-click={submenu_open(@id)}
        class={Helpers.classes(@paperize, item_classes(false), @class)}
      >
        <Icon.pp_icon :if={@icon} name={@icon} class="shrink-0 opacity-80" />
        <span class="min-w-0 flex-1 truncate text-start">{@label}</span>
        <Icon.pp_icon name="hero-chevron-right" size="sm" class="shrink-0 opacity-80 rtl:rotate-180" />
      </button>
      <div
        id={"#{@id}-panel"}
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        data-pp-component="menu-panel"
        class={[
          "group/menu absolute -top-1 z-50 hidden group-hover/sub:flex group-focus-within/sub:flex group-has-[[aria-expanded=true]]/sub:flex",
          submenu_side(@side),
          Helpers.classes(@paperize, panel_classes("standard"), nil)
        ]}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # Opening by click (touch, Safari): the expanded attribute shows the
  # panel through CSS, synchronously, so focus can move into it right away.
  @doc false
  def submenu_open(id) do
    {"aria-expanded", "true"}
    |> JS.set_attribute(to: "##{id}-trigger")
    |> JS.focus_first(to: "##{id}-panel")
  end

  defp submenu_side("end"), do: "start-full ps-1"
  defp submenu_side("start"), do: "end-full pe-1"

  @doc """
  A `Phoenix.LiveView.JS` command that opens/closes the menu with `id` —
  wired to the trigger; public for anything else that should toggle it.
  """
  def toggle(js \\ %JS{}, id) do
    js
    |> JS.toggle(to: "##{id}-panel", display: "flex")
    |> JS.toggle_attribute({"aria-expanded", "true", "false"}, to: "##{id}-trigger")
  end

  @doc "A `Phoenix.LiveView.JS` command that closes the menu with `id`."
  def close(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-panel")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-trigger")
    |> JS.set_attribute({"aria-expanded", "false"}, to: "##{id}-panel [aria-haspopup=menu]")
  end

  defp icon_variant(v) when v in ~w(standard filled tonal outlined), do: v
  defp icon_variant(_v), do: "standard"

  defp button_variant(v) when v in ~w(filled tonal elevated outlined text), do: v
  defp button_variant(_v), do: "text"

  defp anchor_classes("bottom-start"), do: "top-full start-0 mt-1"
  defp anchor_classes("bottom-end"), do: "top-full end-0 mt-1"
  defp anchor_classes("top-start"), do: "bottom-full start-0 mb-1"
  defp anchor_classes("top-end"), do: "bottom-full end-0 mb-1"

  defp panel_classes("standard"),
    do:
      "min-w-[112px] max-w-[280px] w-max flex-col gap-0.5 rounded-pp-lg bg-pp-surface-container p-1 text-pp-on-surface pp-elevation-2"

  defp panel_classes("vibrant"),
    do:
      "min-w-[112px] max-w-[280px] w-max flex-col gap-0.5 rounded-pp-lg bg-pp-tertiary-container p-1 text-pp-on-tertiary-container pp-elevation-2"

  defp item_classes(selected) do
    [
      "relative flex min-h-12 w-full cursor-pointer select-none items-center gap-3 overflow-hidden px-3 py-2 pp-label-large pp-state-layer pp-focus-ring pp-motion-effects-fast",
      "disabled:pointer-events-none disabled:opacity-38 aria-disabled:pointer-events-none aria-disabled:opacity-38",
      if(selected,
        do:
          "rounded-pp-md bg-pp-secondary-container text-pp-on-secondary-container group-data-[pp-color=vibrant]/menu:bg-pp-tertiary group-data-[pp-color=vibrant]/menu:text-pp-on-tertiary",
        else: "rounded-pp-sm"
      )
    ]
  end
end
