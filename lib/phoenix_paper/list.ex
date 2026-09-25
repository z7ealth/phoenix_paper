defmodule PhoenixPaper.List do
  @moduledoc """
  A Material Design list container (`pp_list/1`) — a vertical stack of
  `PhoenixPaper.ListItem`s (and optionally `PhoenixPaper.ListSubheader`/
  `PhoenixPaper.Divider`).

      <.pp_list>
        <.pp_list_subheader>Main</.pp_list_subheader>
        <.pp_list_item navigate={~p"/"}>Home</.pp_list_item>
        <.pp_list_item navigate={~p"/inbox"}>Inbox</.pp_list_item>
        <.pp_divider />
        <.pp_list_subheader>Account</.pp_list_subheader>
        <.pp_list_item navigate={~p"/settings"}>Settings</.pp_list_item>
      </.pp_list>

  Renders `role="list"` on a `<div>` rather than `<ul>`/`<li>` so items are
  free to render as `<a>`, `<button>`, or `<div>` depending on their own
  attrs (see `PhoenixPaper.ListItem`) without fighting list-item content
  model rules.

  ## Density and indentation

  - `dense` makes every item inside compact (the same as `dense` on each
    `pp_list_item`), MUI's `<List dense>`. Useful for a long sidebar.
  - `nested` indents the whole list one step (`pl-4`), for a sub-list
    under a parent item — MUI's nested-list `sx={{ pl: 4 }}`.
  - `inset` lines up the text of items *without* a `:leading` icon with
    the text of items that have one (MUI's `ListItemText inset`), and
    does the same for subheaders.

  All three reach the items with a descendant selector on the list
  (`[&_[data-pp-component=list-item]]:...`), the same technique `Table`'s
  `dense` uses (see AGENTS.md) — there's no way for a parent component to
  set a child component's attrs in HEEx.

  ## Collapsible groups

  `pp_list_group/1` is a list item that expands to show a nested list —
  MUI's nested `List` inside a `Collapse`, as one component:

      <.pp_list dense>
        <.pp_list_item navigate={~p"/"}>Home</.pp_list_item>
        <.pp_list_group id="nav-forms" default_open>
          <:leading><.pp_icon name="hero-pencil-square" /></:leading>
          <:label>Forms</:label>
          <.pp_list_item navigate={~p"/forms/input"}>Input</.pp_list_item>
          <.pp_list_item navigate={~p"/forms/select"}>Select</.pp_list_item>
        </.pp_list_group>
      </.pp_list>

  It works the same way as `PhoenixPaper.Collapse` (a hidden checkbox, a
  `<label>` trigger, height animated with CSS grid rows, no JS), with the
  trigger styled as a list item. The trigger carries
  `data-pp-component="list-item"`, so the list's `dense`/`inset` and a
  colored `PhoenixPaper.Drawer`'s text/hover colors reach it like any
  other item. The nested items are indented one step. It lives in this
  module rather than its own because it has no use outside a list.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Collapse, Helpers}
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:dense, :boolean, default: false, doc: "compact rows for every item inside")
  attr(:nested, :boolean, default: false, doc: "indent the whole list one step")

  attr(:inset, :boolean,
    default: false,
    doc: "align items without a leading icon with those that have one"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a list. See the module doc."
  def pp_list(assigns) do
    ~H"""
    <div
      role="list"
      data-pp-component="list"
      class={Helpers.classes(@paperize, list_classes(@dense, @nested, @inset), @class)}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:id, :string, required: true, doc: "unique id, used to wire the toggle")
  attr(:default_open, :boolean, default: false)
  attr(:dense, :boolean, default: false, doc: "compact trigger row")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:leading, doc: "an icon for the group's own row")
  slot(:label, required: true, doc: "the group's own row text")
  slot(:inner_block, required: true, doc: "the nested items")

  @doc "Renders a collapsible group of list items. See the module doc."
  def pp_list_group(assigns) do
    ~H"""
    <div
      role="listitem"
      data-pp-component="list-group"
      class={Helpers.classes(@paperize, nil, @class)}
      {@rest}
    >
      <input
        type="checkbox"
        id={Collapse.toggle_id(@id)}
        checked={@default_open}
        aria-controls={Collapse.content_id(@id)}
        class="peer sr-only"
      />
      <label
        for={Collapse.toggle_id(@id)}
        data-pp-component="list-item"
        class={["cursor-pointer", Helpers.classes(@paperize, group_trigger_classes(@dense), nil)]}
      >
        <span
          :if={@leading != []}
          data-pp-list-item-leading
          class="flex shrink-0 items-center justify-center [&>*]:size-6"
        >
          {render_slot(@leading)}
        </span>
        <span class="block min-w-0 flex-1 truncate text-sm">{render_slot(@label)}</span>
        <span
          :if={@paperize}
          data-pp-collapse-icon
          class="inline-flex shrink-0 transition-transform duration-200"
        >
          <.pp_icon name="hero-chevron-down-mini" class="!size-5" />
        </span>
      </label>
      <div id={Collapse.content_id(@id)} class={Collapse.content_classes()}>
        <div class="min-h-0 overflow-hidden">
          <div role="list" class={Helpers.classes(@paperize, "flex flex-col pl-4", nil)}>
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp list_classes(dense, nested, inset) do
    ["flex flex-col py-1", dense_classes(dense), nested_classes(nested), inset_classes(inset)]
  end

  defp dense_classes(true), do: "[&_[data-pp-component=list-item]]:py-1"
  defp dense_classes(false), do: ""

  defp nested_classes(true), do: "pl-4"
  defp nested_classes(false), do: ""

  # px-4 item padding + size-6 leading icon + gap-3 = 13 spacing units.
  defp inset_classes(true),
    do:
      "[&_[data-pp-component=list-item]:not(:has([data-pp-list-item-leading]))]:pl-13 [&_[data-pp-component=list-subheader]]:pl-13"

  defp inset_classes(false), do: ""

  defp group_trigger_classes(dense) do
    [
      "flex select-none items-center gap-3 rounded-full px-4 text-pp-on-surface transition-colors hover:bg-pp-on-surface/10 peer-focus-visible:outline peer-focus-visible:outline-2 peer-focus-visible:outline-pp-primary peer-checked:[&>[data-pp-collapse-icon]]:rotate-180",
      if(dense, do: "py-1", else: "py-2")
    ]
  end
end
