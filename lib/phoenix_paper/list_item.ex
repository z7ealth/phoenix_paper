defmodule PhoenixPaper.ListItem do
  @moduledoc """
  An MD3 list item (`pp_list_item/1`) — for inside `PhoenixPaper.List`,
  but also usable on its own (e.g. inside a `PhoenixPaper.Card`).

  [Live demo →](https://phoenixpaper.dev/components/navigation#list)

  MD3 look: a 56dp row (72dp with a `:secondary` line) with 16dp side
  padding; the headline is `body-large`, the supporting line `body-medium`
  in `on-surface-variant`, the `:leading` icon `on-surface-variant` (an
  avatar keeps its own colors), the `:trailing` content `label-small`.
  Linked items get the state layer and focus ring.

  ## Three-line items

  By default the text is cut to one line each with "…" (MD3's one- and
  two-line items). `three_line` makes it MD3's three-line item, for
  longer text: an 88dp row with 12dp top and bottom padding, the
  supporting line wrapping to up to two lines, the headline wrapping
  instead of being cut, and the leading and trailing content aligned to
  the top instead of centered.

      <.pp_list_item three_line>
        Close tab
        <:secondary>Asks first if the tab is still uploading or has unsaved changes.</:secondary>
      </.pp_list_item>

  MD3 (like its Compose implementation) makes an item three-line when its
  supporting text runs onto a second line. CSS can't tell when text has
  wrapped, so here the caller says so.

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

  attr(:three_line, :boolean,
    default: false,
    doc: "MD3's three-line item: text wraps (supporting text up to two lines), 88dp, top-aligned"
  )

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
      class={Helpers.classes(@paperize, item_classes(@active, @disabled, @ripple?, true, @three_line), @class)}
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
      class={Helpers.classes(@paperize, item_classes(@active, @disabled, false, false, @three_line), @class)}
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
      <span class={Helpers.classes(@paperize, headline_classes(@three_line), nil)}>
        {render_slot(@inner_block)}
      </span>
      <span
        :if={@secondary != []}
        class={Helpers.classes(@paperize, supporting_classes(@three_line), nil)}
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
  # the content taller; min-h covers the one-line case). Three-line items
  # are 88dp with 12dp vertical padding, and their leading/trailing
  # content sits at the top (Compose offsets it by the top padding).
  defp item_classes(active, disabled, ripple, linked, three_line) do
    [
      "relative flex gap-4 overflow-hidden px-4 pp-motion-effects-fast",
      if(three_line, do: "min-h-[88px] items-start py-3", else: "min-h-14 items-center py-2"),
      linked && "cursor-pointer pp-state-layer pp-focus-ring",
      state_classes(active),
      disabled && "pointer-events-none opacity-38",
      Ripple.container_classes(ripple)
    ]
  end

  # One- and two-line items cut each line with an ellipsis; three-line
  # items wrap the headline and clamp the supporting text at MD3's two
  # lines (`break-words` so a long URL can't push the row wider).
  defp headline_classes(false), do: "block truncate pp-body-large"
  defp headline_classes(true), do: "block break-words pp-body-large"

  defp supporting_classes(false),
    do: "block truncate pp-body-medium text-pp-on-surface-variant [[aria-current]_&]:text-inherit"

  defp supporting_classes(true),
    do:
      "block line-clamp-2 break-words pp-body-medium text-pp-on-surface-variant [[aria-current]_&]:text-inherit"

  defp state_classes(true), do: "bg-pp-secondary-container text-pp-on-secondary-container"
  defp state_classes(false), do: "text-pp-on-surface"
end
