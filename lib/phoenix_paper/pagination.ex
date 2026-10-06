defmodule PhoenixPaper.Pagination do
  @moduledoc """
  Page navigation (`pp_pagination/1`) built from MD3 icon buttons:
  previous/next around a run of page numbers, collapsed with an ellipsis
  when there are many. For a table's "rows per page / 1–10 of 47" footer,
  see `PhoenixPaper.TablePagination`.

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

  The first and last page, the current page and one on each side; any
  longer run collapses into `…`. The list keeps the same length while you
  page through, so the control doesn't change width. `items/2` computes
  it and is public if you need it.

  ## Look

  MD3 has no pagination component, so this is a row of MD3 standard icon
  buttons (40dp, `label-large` numbers in `on-surface-variant`, state
  layer, focus ring, Expressive press morph). The current page takes
  MD3's selected color, `secondary-container`, and `aria-current="page"`.
  A control that can't move (previous on page 1) is a disabled button,
  never a link to page 0.

  ## Migrating from 0.4

  `sibling_count`, `boundary_count`, `show_first_button`,
  `show_last_button`, `hide_prev_button`, `hide_next_button`, `variant`,
  `shape`, `size` and `color` are gone (MUI's pagination options), and
  `items/4` is now `items/2`.
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
  attr(:disabled, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders page navigation. See the module doc."
  def pp_pagination(assigns) do
    %{page: page, count: count} = assigns

    controls =
      [{:previous, page - 1, page <= 1}] ++
        Enum.map(items(page, count), fn
          n when is_integer(n) -> {:page, n, false}
          ellipsis -> {ellipsis, nil, true}
        end) ++
        [{:next, page + 1, page >= count}]

    assigns = assign(assigns, :controls, controls)

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
                item_classes(kind, kind == :page and to == @page),
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

  defp control_content(%{kind: :previous} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-left" size="md" />|

  defp control_content(%{kind: :next} = assigns),
    do: ~H|<.pp_icon name="hero-chevron-right" size="md" />|

  defp aria_label(:page, page), do: "Go to page #{page}"
  defp aria_label(:previous, _page), do: "Go to previous page"
  defp aria_label(:next, _page), do: "Go to next page"

  @doc """
  The page numbers to show for `page` of `count`, with `:start_ellipsis`/
  `:end_ellipsis` where a run is collapsed: the first and last page, the
  current one and one on each side. The list length stays constant while
  paging.

      iex> PhoenixPaper.Pagination.items(1, 5)
      [1, 2, 3, 4, 5]

      iex> PhoenixPaper.Pagination.items(6, 20)
      [1, :start_ellipsis, 5, 6, 7, :end_ellipsis, 20]

      iex> PhoenixPaper.Pagination.items(1, 20)
      [1, 2, 3, 4, 5, :end_ellipsis, 20]
  """
  @spec items(integer(), integer()) :: [pos_integer() | :start_ellipsis | :end_ellipsis]
  def items(page, count) do
    sibling_count = 1
    boundary_count = 1

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

  defp item_classes(kind, _selected) when kind in [:start_ellipsis, :end_ellipsis],
    do:
      "inline-flex h-10 min-w-10 select-none items-center justify-center pp-label-large text-pp-on-surface-variant"

  defp item_classes(_kind, selected) do
    [
      "relative inline-flex h-10 min-w-10 cursor-pointer select-none items-center justify-center overflow-hidden rounded-[20px] px-2 pp-label-large pp-state-layer pp-focus-ring pp-motion-spatial-fast active:rounded-pp-sm disabled:pointer-events-none disabled:text-pp-on-surface/38",
      if(selected,
        do: "bg-pp-secondary-container text-pp-on-secondary-container",
        else: "text-pp-on-surface-variant"
      )
    ]
  end
end
