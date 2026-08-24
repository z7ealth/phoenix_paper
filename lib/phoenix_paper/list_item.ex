defmodule PhoenixPaper.ListItem do
  @moduledoc """
  A Material Design list item (`pp_list_item/1`) — for inside
  `PhoenixPaper.List`, but also usable on its own (e.g. inside a
  `PhoenixPaper.Card`).

  Renders as a `Phoenix.Component.link/1` (so `href`/`navigate`/`patch` all
  work) when any of those are set, or a plain `<div>` otherwise — a static
  info row doesn't need to be a link. Whether an item is "active" isn't
  derived automatically (this is a stateless function component with no
  knowledge of the current request) — the caller passes `active` based on
  its own route, e.g. `active={@current_path == "/settings"}`.

  Ripples on click/tap by default when it's a link (see
  `PhoenixPaper.Ripple`) — `ripple` has no effect on a non-link item, since
  there's nothing to click.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:active, :boolean, default: false)
  attr(:ripple, :boolean, default: true, doc: "the Material ripple effect on click/tap")
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:leading, doc: "an icon or avatar")
  slot(:inner_block, required: true, doc: "the primary line of text")
  slot(:secondary, doc: "a secondary line of text below the primary one")
  slot(:trailing, doc: "a trailing icon, badge, or action")

  @doc "Renders a list item. See the module doc."
  def pp_list_item(assigns) do
    linked? =
      assigns.href not in [nil, false] or assigns.navigate not in [nil, false] or
        assigns.patch not in [nil, false]

    assigns =
      assigns
      |> assign(:linked?, linked?)
      |> assign(:ripple?, linked? and assigns.ripple)

    ~H"""
    <.link
      :if={@linked?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      role="listitem"
      aria-disabled={to_string(@disabled)}
      data-pp-component="list-item"
      class={Helpers.classes(@paperize, item_classes(@active, @disabled, @ripple?, true), @class)}
      onclick={Ripple.on_click(@ripple?)}
      {@rest}
    >
      {item_content(assigns)}
    </.link>
    <div
      :if={!@linked?}
      role="listitem"
      aria-disabled={to_string(@disabled)}
      data-pp-component="list-item"
      class={Helpers.classes(@paperize, item_classes(@active, @disabled, false, false), @class)}
      {@rest}
    >
      {item_content(assigns)}
    </div>
    """
  end

  defp item_content(assigns) do
    ~H"""
    <span :if={@leading != []} class="flex shrink-0 items-center justify-center [&>*]:size-6">
      {render_slot(@leading)}
    </span>
    <span class="min-w-0 flex-1">
      <span class="block truncate text-sm">{render_slot(@inner_block)}</span>
      <span :if={@secondary != []} class="block truncate text-xs text-pp-outline">
        {render_slot(@secondary)}
      </span>
    </span>
    <span :if={@trailing != []} class="flex shrink-0 items-center">{render_slot(@trailing)}</span>
    """
  end

  defp item_classes(active, disabled, ripple, linked) do
    [
      base_classes(),
      cursor_classes(linked),
      state_classes(active),
      disabled_classes(disabled),
      Ripple.container_classes(ripple)
    ]
  end

  defp base_classes do
    "flex items-center gap-3 rounded-full px-4 py-2 transition-colors"
  end

  defp cursor_classes(true), do: "cursor-pointer"
  defp cursor_classes(false), do: ""

  defp state_classes(true), do: "bg-pp-primary/10 text-pp-primary"
  defp state_classes(false), do: "text-pp-on-surface hover:bg-pp-on-surface/10"

  defp disabled_classes(true), do: "pointer-events-none opacity-40"
  defp disabled_classes(false), do: ""
end
