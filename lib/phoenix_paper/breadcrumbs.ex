defmodule PhoenixPaper.Breadcrumbs do
  @moduledoc """
  A breadcrumb trail (`pp_breadcrumbs/1`) built from MD3 parts: a row of
  `:item`s with a chevron between them.

      <.pp_breadcrumbs>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/catalog"}>Catalog</:item>
        <:item>Current product</:item>
      </.pp_breadcrumbs>

  MD3 has no breadcrumbs component, so the parts are MD3's: each linked
  item is a compact text button (`label-large` in `primary`, with the
  state layer and focus ring), the current page is plain `label-large`
  text in `on-surface`, and the separator is a `hero-chevron-right` icon
  in `on-surface-variant` (mirrored in right-to-left layouts). A long
  trail wraps onto the next line.

  An `:item` with `href`/`navigate`/`patch` renders as a
  `Phoenix.Component.link/1`; one without renders as text with
  `aria-current="page"`. Which item is current isn't inferred from its
  position — this is a stateless component with no knowledge of the
  request — it's whichever item you leave without a link.

  ## Migrating from 0.4

  `max_items`, `items_before_collapse`, `items_after_collapse`,
  `expand_text` and the `:separator` slot are gone (they came from MUI's
  breadcrumbs): the separator is MD3's chevron and the trail wraps
  instead of collapsing.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-label))

  slot :item, required: true do
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
  end

  @doc "Renders a breadcrumb trail. See the module doc."
  def pp_breadcrumbs(assigns) do
    assigns =
      assign(
        assigns,
        :entries,
        assigns.item |> Enum.map(&{:item, &1}) |> Enum.intersperse(:separator)
      )

    ~H"""
    <nav
      aria-label="breadcrumb"
      data-pp-component="breadcrumbs"
      class={Helpers.classes(@paperize, nil, @class)}
      {@rest}
    >
      <ol class="flex flex-wrap items-center gap-1">
        <.entry :for={e <- @entries} entry={e} paperize={@paperize} />
      </ol>
    </nav>
    """
  end

  # The `<li>`s' flex layout stays on under `paperize={false}`: there's no
  # `class` attr on an individual item to rebuild it with (see AGENTS.md).
  defp entry(%{entry: :separator} = assigns) do
    ~H"""
    <li aria-hidden="true" class="flex items-center">
      <.pp_icon
        name="hero-chevron-right"
        size="sm"
        class={Helpers.classes(@paperize, "text-pp-on-surface-variant rtl:rotate-180", nil)}
      />
    </li>
    """
  end

  defp entry(%{entry: {:item, item}} = assigns) do
    linked? =
      item[:href] not in [nil, false] or item[:navigate] not in [nil, false] or
        item[:patch] not in [nil, false]

    assigns = assign(assigns, item: item, linked?: linked?)

    ~H"""
    <li class="flex items-center">
      <.link
        :if={@linked?}
        href={@item[:href]}
        navigate={@item[:navigate]}
        patch={@item[:patch]}
        class={Helpers.classes(@paperize, link_classes(), nil)}
      >
        {render_slot(@item)}
      </.link>
      <span
        :if={!@linked?}
        aria-current="page"
        class={Helpers.classes(@paperize, "px-1 pp-label-large text-pp-on-surface", nil)}
      >
        {render_slot(@item)}
      </span>
    </li>
    """
  end

  defp link_classes do
    "relative inline-flex min-h-8 items-center overflow-hidden rounded-pp-full px-2 pp-label-large text-pp-primary no-underline pp-state-layer pp-focus-ring"
  end
end
