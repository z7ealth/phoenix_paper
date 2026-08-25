defmodule PhoenixPaper.Breadcrumbs do
  @moduledoc """
  A Material Design breadcrumb trail (`pp_breadcrumbs/1`), in the spirit of
  MUI's `Breadcrumbs` — a horizontal list of `:item`s with a separator
  automatically inserted between them.

      <.pp_breadcrumbs>
        <:item navigate={~p"/"}>Home</:item>
        <:item navigate={~p"/catalog"}>Catalog</:item>
        <:item>Current product</:item>
      </.pp_breadcrumbs>

  Each `:item` renders as a `Phoenix.Component.link/1` when it has an
  `href`/`navigate`/`patch`, or as plain `aria-current="page"` text
  otherwise — the exact same "conditional root tag" convention
  `PhoenixPaper.ListItem` uses (see AGENTS.md), and just like `ListItem`,
  which item is "current" isn't detected by position (it's *not* always
  assumed to be the last one) — this is a stateless function component
  with no knowledge of the current request, so it's simply whichever
  `:item` you leave without a link. Every one of MUI's own docs examples
  follows that same convention (only the last child is plain `Typography`,
  every other one is a `Link`), so this isn't a departure from upstream,
  just made explicit.

  `separator` is a slot, not a string attr, so it can hold anything MUI's
  own `separator` prop can — an icon, not just text:

      <.pp_breadcrumbs>
        <:separator><.pp_icon name="hero-chevron-right" class="size-4" /></:separator>
        <:item navigate={~p"/"}>Home</:item>
        <:item>Settings</:item>
      </.pp_breadcrumbs>

  omit it for MUI's plain `"/"` default.

  ## Collapsing (`max_items`)

  Beyond `max_items` items (default 8, matching MUI), the trail collapses
  to `items_before_collapse` (default 1) + an ellipsis + `items_after_collapse`
  (default 1), with a click on the ellipsis expanding to the full list —
  pure CSS, no JS/LiveView, the same hidden-checkbox-plus-`peer-checked:`
  trick `PhoenixPaper.Accordion`/`PhoenixPaper.Drawer` use. Unlike those,
  the checkbox's `id` is generated internally (via `System.unique_integer/1`)
  rather than caller-supplied: nothing outside this component ever needs to
  reference it, unlike `Accordion`'s id (shared with `AccordionSummary`/
  `Details`/`Actions`) or `Drawer`'s (referenced by an external
  `pp_drawer_toggle`). Both the collapsed and the fully-expanded `<ol>` are
  always rendered (one hidden via `peer-checked:hidden`/`peer-checked:flex`
  swapping which is visible) — the same "always in the DOM, toggle
  visibility" trade-off as `Dialog`, needed because there's no JS here to
  swap markup after the fact. Once expanded, there's no way back to
  collapsed — like a checked radio (see `Accordion`'s moduledoc), a checked
  checkbox can't be unchecked by clicking a label pointing at it again;
  MUI's own JS-driven version has the same one-way limitation for the same
  reason (there's no "re-collapse" affordance in their demo either, only
  page navigation resets it).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:max_items, :integer,
    default: 8,
    doc: "collapse into an expandable ellipsis beyond this many items"
  )

  attr(:items_before_collapse, :integer, default: 1)
  attr(:items_after_collapse, :integer, default: 1)

  attr(:expand_text, :string,
    default: "Show path",
    doc: "aria-label for the ellipsis expand control"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(aria-label))

  slot :item, required: true do
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
  end

  slot(:separator, doc: ~s(custom separator content, e.g. an icon — defaults to "/"))

  @doc "Renders a breadcrumb trail. See the module doc."
  def pp_breadcrumbs(assigns) do
    collapse? = length(assigns.item) > assigns.max_items

    assigns =
      assigns
      |> assign(:collapse?, collapse?)
      |> assign_new(:expand_id, fn -> "pp-breadcrumbs-#{System.unique_integer([:positive])}" end)
      |> assign(:full_entries, entries(assigns.item))
      |> assign(
        :collapsed_entries,
        collapse? &&
          collapsed_entries(
            assigns.item,
            assigns.items_before_collapse,
            assigns.items_after_collapse
          )
      )

    ~H"""
    <nav
      aria-label="breadcrumb"
      data-pp-component="breadcrumbs"
      class={Helpers.classes(@paperize, "text-sm", @class)}
      {@rest}
    >
      <input :if={@collapse?} type="checkbox" id={@expand_id} class="peer sr-only" />
      <ol :if={@collapse?} class="flex flex-wrap items-center gap-1 peer-checked:hidden">
        <.entry
          :for={e <- @collapsed_entries}
          entry={e}
          separator={@separator}
          expand_id={@expand_id}
          expand_text={@expand_text}
          paperize={@paperize}
        />
      </ol>
      <ol class={list_classes(@collapse?)}>
        <.entry
          :for={e <- @full_entries}
          entry={e}
          separator={@separator}
          expand_id={@expand_id}
          expand_text={@expand_text}
          paperize={@paperize}
        />
      </ol>
    </nav>
    """
  end

  defp list_classes(false), do: "flex flex-wrap items-center gap-1"
  defp list_classes(true), do: "hidden flex-wrap items-center gap-1 peer-checked:flex"

  defp entries(items), do: items |> Enum.map(&{:item, &1}) |> Enum.intersperse(:separator)

  defp collapsed_entries(items, before_n, after_n) do
    before = items |> Enum.take(before_n) |> Enum.map(&{:item, &1})
    after_items = items |> Enum.take(-after_n) |> Enum.map(&{:item, &1})

    (before ++ [:ellipsis] ++ after_items) |> Enum.intersperse(:separator)
  end

  defp entry(%{entry: :separator} = assigns) do
    ~H"""
    <li aria-hidden="true" class={["flex items-center", Helpers.classes(@paperize, "text-pp-outline", nil)]}>
      {if @separator == [], do: "/", else: render_slot(@separator)}
    </li>
    """
  end

  defp entry(%{entry: :ellipsis} = assigns) do
    ~H"""
    <li class="flex items-center">
      <label
        for={@expand_id}
        class={
          Helpers.classes(
            @paperize,
            "cursor-pointer rounded px-1 text-pp-outline transition-colors select-none hover:bg-pp-on-surface/10 hover:text-pp-on-surface",
            nil
          )
        }
        aria-label={@expand_text}
      >
        &hellip;
      </label>
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
        class={Helpers.classes(@paperize, "text-pp-primary hover:underline", nil)}
      >
        {render_slot(@item)}
      </.link>
      <span
        :if={!@linked?}
        aria-current="page"
        class={Helpers.classes(@paperize, "font-medium text-pp-on-surface", nil)}
      >
        {render_slot(@item)}
      </span>
    </li>
    """
  end
end
