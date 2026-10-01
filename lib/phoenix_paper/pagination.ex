defmodule PhoenixPaper.Pagination do
  @moduledoc """
  Page navigation (`pp_pagination/1`), in the spirit of MUI's
  [`Pagination`](https://mui.com/material-ui/react-pagination/): previous/
  next buttons around a run of page numbers, collapsed with an ellipsis when
  there are many. For a table's "rows per page / 1–10 of 47" footer, see
  `PhoenixPaper.TablePagination`.

  Pages are **1-based**. The component is stateless: it renders the `page`
  you pass, and each button either links or fires an event.

  ## Links (the common case)

  Give `path` a one-argument function from a page number to a URL; each
  page becomes a `patch` link by default (`link="navigate"` or `"href"` for
  the other kinds), so the page lives in the URL and `handle_params/3`
  loads it:

      <.pp_pagination page={@page} count={@total_pages} path={&~p"/users?page=\#{&1}"} />

  ## Events

  Or give `on_change` an event name: each button sends it with a
  `"page"` value (`phx-value-page`), and `target` sets `phx-target`:

      <.pp_pagination page={@page} count={@total_pages} on_change="paginate" />

      def handle_event("paginate", %{"page" => page}, socket), do: ...

  ## Which pages are shown

  `sibling_count` pages on each side of the current one and
  `boundary_count` pages at each end, the rest collapsed into `…` (MUI's
  algorithm, so the control keeps the same width while you page through).
  `items/4` computes that list and is public if you need it.

  ## Look

  `variant` (`text`/`outlined`), `shape` (`circular`/`rounded`), `size`
  (`small`/`medium`/`large`), and `color` (`standard`/`primary`/
  `secondary`/`accent`) for the selected page: `standard` is a grey tint,
  the brand colors fill it (`text`) or tint and outline it (`outlined`).
  `show_first_button`/`show_last_button` add jump-to-end buttons;
  `hide_prev_button`/`hide_next_button` drop the arrows.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:page, :integer, required: true, doc: "the current page, 1-based")
  attr(:count, :integer, required: true, doc: "the number of pages")

  attr(:path, :any,
    default: nil,
    doc: "a function from a page number to a URL; makes every page a link"
  )

  attr(:link, :string,
    default: "patch",
    values: ~w(patch navigate href),
    doc: "the kind of link path produces"
  )

  attr(:on_change, :any,
    default: nil,
    doc: "an event name (or JS) for phx-click; the page is sent as phx-value-page"
  )

  attr(:target, :any, default: nil, doc: "phx-target for on_change")
  attr(:sibling_count, :integer, default: 1)
  attr(:boundary_count, :integer, default: 1)
  attr(:variant, :string, default: "text", values: ~w(text outlined))
  attr(:shape, :string, default: "circular", values: ~w(circular rounded))
  attr(:size, :string, default: "medium", values: ~w(small medium large))
  attr(:color, :string, default: "primary", values: ~w(standard primary secondary accent))
  attr(:show_first_button, :boolean, default: false)
  attr(:show_last_button, :boolean, default: false)
  attr(:hide_prev_button, :boolean, default: false)
  attr(:hide_next_button, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders page navigation. See the module doc."
  def pp_pagination(assigns) do
    %{page: page, count: count} = assigns

    controls =
      [
        assigns.show_first_button && {:first, 1, page <= 1},
        !assigns.hide_prev_button && {:previous, page - 1, page <= 1}
      ] ++
        Enum.map(items(page, count, assigns.sibling_count, assigns.boundary_count), fn
          n when is_integer(n) -> {:page, n, false}
          ellipsis -> {ellipsis, nil, true}
        end) ++
        [
          !assigns.hide_next_button && {:next, page + 1, page >= count},
          assigns.show_last_button && {:last, count, page >= count}
        ]

    assigns = assign(assigns, :controls, Enum.filter(controls, & &1))

    ~H"""
    <nav
      aria-label="pagination navigation"
      data-pp-component="pagination"
      class={Helpers.classes(@paperize, nil, @class)}
      {@rest}
    >
      <ul class="flex flex-wrap items-center gap-1">
        <li :for={{kind, to, off?} <- @controls}>
          <.control
            kind={kind}
            to={to}
            selected={kind == :page and to == @page}
            disabled={@disabled or off?}
            path={@path}
            link={@link}
            on_change={@on_change}
            target={@target}
            classes={
              Helpers.classes(
                @paperize,
                item_classes(kind, @variant, @shape, @size, @color, kind == :page and to == @page),
                nil
              )
            }
          />
        </li>
      </ul>
    </nav>
    """
  end

  attr(:kind, :atom, required: true)
  attr(:to, :integer)
  attr(:selected, :boolean, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:path, :any, required: true)
  attr(:link, :string, required: true)
  attr(:on_change, :any, required: true)
  attr(:target, :any, required: true)
  attr(:classes, :string, required: true)

  defp control(%{kind: kind} = assigns) when kind in [:start_ellipsis, :end_ellipsis] do
    ~H"""
    <span class={@classes} aria-hidden="true">…</span>
    """
  end

  defp control(%{path: path, disabled: false} = assigns) when is_function(path, 1) do
    url = assigns.path.(assigns.to)

    assigns =
      assign(assigns,
        href: assigns.link == "href" && url,
        navigate: assigns.link == "navigate" && url,
        patch: assigns.link == "patch" && url
      )

    ~H"""
    <.link
      href={@href || nil}
      navigate={@navigate || nil}
      patch={@patch || nil}
      class={@classes}
      aria-label={aria_label(@kind, @to)}
      aria-current={@selected && "page"}
    >
      <.control_content kind={@kind} to={@to} />
    </.link>
    """
  end

  defp control(assigns) do
    ~H"""
    <button
      type="button"
      disabled={@disabled}
      phx-click={!@disabled && @on_change}
      phx-value-page={!@disabled && @on_change && @to}
      phx-target={!@disabled && @on_change && @target}
      class={@classes}
      aria-label={aria_label(@kind, @to)}
      aria-current={@selected && "page"}
    >
      <.control_content kind={@kind} to={@to} />
    </button>
    """
  end

  attr(:kind, :atom, required: true)
  attr(:to, :integer)

  defp control_content(%{kind: :page} = assigns), do: ~H"{@to}"

  defp control_content(%{kind: :first} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-double-left-mini" />|

  defp control_content(%{kind: :previous} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-left-mini" />|

  defp control_content(%{kind: :next} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-right-mini" />|

  defp control_content(%{kind: :last} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-double-right-mini" />|

  defp aria_label(:page, page), do: "Go to page #{page}"
  defp aria_label(:first, _page), do: "Go to first page"
  defp aria_label(:previous, _page), do: "Go to previous page"
  defp aria_label(:next, _page), do: "Go to next page"
  defp aria_label(:last, _page), do: "Go to last page"

  @doc """
  The page numbers to show for `page` of `count`, with `:start_ellipsis`/
  `:end_ellipsis` where a run is collapsed. Same algorithm as MUI's
  `usePagination`, so the list length stays constant while paging.

      iex> PhoenixPaper.Pagination.items(1, 5, 1, 1)
      [1, 2, 3, 4, 5]

      iex> PhoenixPaper.Pagination.items(6, 20, 1, 1)
      [1, :start_ellipsis, 5, 6, 7, :end_ellipsis, 20]

      iex> PhoenixPaper.Pagination.items(1, 20, 1, 1)
      [1, 2, 3, 4, 5, :end_ellipsis, 20]
  """
  @spec items(integer(), integer(), non_neg_integer(), non_neg_integer()) ::
          [pos_integer() | :start_ellipsis | :end_ellipsis]
  def items(page, count, sibling_count, boundary_count) do
    start_pages = range(1, min(boundary_count, count))
    end_pages = range(max(count - boundary_count + 1, boundary_count + 1), count)

    siblings_start =
      max(
        min(page - sibling_count, count - boundary_count - sibling_count * 2 - 1),
        boundary_count + 2
      )

    siblings_end =
      min(
        max(page + sibling_count, boundary_count + sibling_count * 2 + 2),
        if(end_pages == [], do: count - 1, else: hd(end_pages) - 2)
      )

    start_gap =
      cond do
        siblings_start > boundary_count + 2 -> [:start_ellipsis]
        boundary_count + 1 < count - boundary_count -> [boundary_count + 1]
        true -> []
      end

    end_gap =
      cond do
        siblings_end < count - boundary_count - 1 -> [:end_ellipsis]
        count - boundary_count > boundary_count -> [count - boundary_count]
        true -> []
      end

    start_pages ++ start_gap ++ range(siblings_start, siblings_end) ++ end_gap ++ end_pages
  end

  defp range(first, last) when first > last, do: []
  defp range(first, last), do: Enum.to_list(first..last)

  defp item_classes(kind, _variant, _shape, size, _color, _selected)
       when kind in [:start_ellipsis, :end_ellipsis],
       do: [
         "inline-flex items-center justify-center select-none text-pp-on-surface",
         size_classes(size)
       ]

  defp item_classes(_kind, variant, shape, size, color, selected) do
    [
      "inline-flex items-center justify-center cursor-pointer select-none transition-colors duration-150 disabled:opacity-40 disabled:pointer-events-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pp-primary",
      size_classes(size),
      shape_class(shape),
      color_classes(variant, color, selected)
    ]
  end

  defp size_classes("small"), do: "h-6 min-w-6 px-1 text-xs"
  defp size_classes("medium"), do: "h-8 min-w-8 px-1.5 text-sm"
  defp size_classes("large"), do: "h-10 min-w-10 px-2 text-base"

  defp shape_class("circular"), do: "rounded-full"
  defp shape_class("rounded"), do: "rounded"

  defp color_classes("text", _color, false),
    do: "text-pp-on-surface hover:bg-pp-on-surface/10"

  defp color_classes("text", "standard", true), do: "bg-pp-on-surface/15 text-pp-on-surface"

  defp color_classes("text", "primary", true),
    do: "bg-pp-primary text-pp-on-primary hover:bg-pp-primary/90"

  defp color_classes("text", "secondary", true),
    do: "bg-pp-secondary text-pp-on-secondary hover:bg-pp-secondary/90"

  defp color_classes("text", "accent", true),
    do: "bg-pp-accent text-pp-on-accent hover:bg-pp-accent/90"

  defp color_classes("outlined", _color, false),
    do: "border border-pp-outline/40 text-pp-on-surface hover:bg-pp-on-surface/10"

  defp color_classes("outlined", "standard", true),
    do: "border border-pp-outline/40 bg-pp-on-surface/15 text-pp-on-surface"

  defp color_classes("outlined", "primary", true),
    do: "border border-pp-primary/50 bg-pp-primary/10 text-pp-primary hover:bg-pp-primary/20"

  defp color_classes("outlined", "secondary", true),
    do:
      "border border-pp-secondary/50 bg-pp-secondary/10 text-pp-secondary hover:bg-pp-secondary/20"

  defp color_classes("outlined", "accent", true),
    do: "border border-pp-accent/50 bg-pp-accent/10 text-pp-accent hover:bg-pp-accent/20"
end
