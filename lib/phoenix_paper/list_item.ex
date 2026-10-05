defmodule PhoenixPaper.ListItem do
  @moduledoc """
  An MD3 list item (`pp_list_item/1`) — for inside `PhoenixPaper.List`,
  but also usable on its own (e.g. inside a `PhoenixPaper.Card`).

  MD3 look: a 56dp row (72dp with a `:secondary` line) with 16dp side
  padding; the headline is `body-large`, the supporting line `body-medium`
  in `on-surface-variant`, the `:leading` icon `on-surface-variant` (an
  avatar keeps its own colors), the `:trailing` content `label-small`.
  Linked items get the state layer and focus ring.

  Renders as a `Phoenix.Component.link/1` (so `href`/`navigate`/`patch` all
  work) when any of those are set, or a plain `<div>` otherwise — a static
  info row doesn't need to be a link. Whether an item is "active" isn't
  derived automatically (this is a stateless function component with no
  knowledge of the current request) — the caller passes `active` based on
  its own route, e.g. `active={@current_path == "/settings"}`.

  `active` gives the row MD3's selected look (`secondary-container`) and
  sets `aria-current="page"`, the correct ARIA for "the current page in a
  navigation list". For app navigation itself, see
  `PhoenixPaper.NavigationRail`/`NavigationBar`.

  Ripples on click/tap by default when it's a link (see
  `PhoenixPaper.Ripple`) — `ripple` has no effect on a non-link item, since
  there's nothing to click.

  When linked, the usual link attributes (`target`, `rel`, `download`,
  `method`, `replace`, ...) pass straight through to the `<a>`, the same
  list `PhoenixPaper.Button` accepts:

      <.pp_list_item href="https://hexdocs.pm" target="_blank" rel="noopener">
        Docs
      </.pp_list_item>
  """
  use Phoenix.Component

  alias PhoenixPaper.{Helpers, Ripple}

  attr(:href, :any, default: nil)
  attr(:navigate, :any, default: nil)
  attr(:patch, :any, default: nil)
  attr(:active, :boolean, default: false)

  attr(:ripple, :boolean,
    default: true,
    doc:
      "the Material ripple effect on click/tap — off whenever paperize is false, see PhoenixPaper.Ripple"
  )

  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(target rel download hreflang referrerpolicy method csrf_token replace),
    doc: "link attrs (target, rel, method, ...) pass through to the link when linked"
  )

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
      |> assign(:ripple?, linked? and assigns.ripple and assigns.paperize)

    ~H"""
    <.link
      :if={@linked?}
      href={@href}
      navigate={@navigate}
      patch={@patch}
      role="listitem"
      aria-disabled={to_string(@disabled)}
      aria-current={@active && "page"}
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
      aria-current={@active && "page"}
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
    <span
      :if={@leading != []}
      data-pp-list-item-leading
      class={Helpers.classes(@paperize, "flex shrink-0 items-center justify-center text-pp-on-surface-variant [[aria-current]>&]:text-inherit", nil)}
    >
      {render_slot(@leading)}
    </span>
    <span class="min-w-0 flex-1">
      <span class={Helpers.classes(@paperize, "block truncate pp-body-large", nil)}>
        {render_slot(@inner_block)}
      </span>
      <span
        :if={@secondary != []}
        class={Helpers.classes(@paperize, "block truncate pp-body-medium text-pp-on-surface-variant [[aria-current]_&]:text-inherit", nil)}
      >
        {render_slot(@secondary)}
      </span>
    </span>
    <span
      :if={@trailing != []}
      class={Helpers.classes(@paperize, "flex shrink-0 items-center pp-label-small text-pp-on-surface-variant", nil)}
    >
      {render_slot(@trailing)}
    </span>
    """
  end

  # MD3 one-line items are 56dp, two-line 72dp (the secondary line makes
  # the content taller; min-h covers the one-line case).
  defp item_classes(active, disabled, ripple, linked) do
    [
      "relative flex min-h-14 items-center gap-4 overflow-hidden px-4 py-2 pp-motion-effects-fast",
      linked && "cursor-pointer pp-state-layer pp-focus-ring",
      state_classes(active),
      disabled && "pointer-events-none opacity-38",
      Ripple.container_classes(ripple)
    ]
  end

  defp state_classes(true), do: "bg-pp-secondary-container text-pp-on-secondary-container"
  defp state_classes(false), do: "text-pp-on-surface"
end
