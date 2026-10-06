defmodule PhoenixPaper.TablePagination do
  @moduledoc """
  A table footer bar (`pp_table_pagination/1`) built from MD3 parts: a
  rows-per-page picker (a `pp_menu`), the "1–10 of 47" range in
  `body-medium`, and previous/next `pp_icon_button`s. For page-number
  navigation (lists, grids, search results), see
  `PhoenixPaper.Pagination`.

      <.pp_table_container>
        <.pp_table>...</.pp_table>
        <.pp_table_pagination
          id="users-pagination"
          page={@page}
          count={@total_rows}
          rows_per_page={@per_page}
          path={&~p"/users?page=\#{&1}&per_page=\#{&2}"}
        />
      </.pp_table_container>

  `page` is **1-based**, the same as `PhoenixPaper.Pagination`. `count`
  is the total number of *rows*, not pages.

  ## Links or events

  Same two modes as `PhoenixPaper.Pagination`:

  - `path` — a **two**-argument function `(page, rows_per_page) -> URL`.
    Previous/next keep `rows_per_page`; picking a new page size goes back to
    page 1. `link` picks `patch` (default), `navigate` or `href`.
  - `on_page_change` / `on_rows_per_page_change` — event names; the
    buttons send `phx-value-page`, the picker sends `phx-value-rows_per_page`
    (both strings, parse them in `handle_event/3`). `target` sets
    `phx-target`.

  The rows-per-page picker is a `PhoenixPaper.Menu` (it needs the `id`), so
  like `Menu` it needs the LiveView JS client loaded on the page. An empty
  `rows_per_page_options` hides it.

  ## Labels

  `rows_per_page_label` (default `"Rows per page:"`) and `range_label`, a
  function receiving `%{from: _, to: _, count: _}` (default
  `"1–10 of 47"`), for translation.

  ## Migrating from 0.4

  `show_first_button`/`show_last_button` are gone, and the labels were
  renamed: `label_rows_per_page` → `rows_per_page_label`,
  `label_displayed_rows` → `range_label`.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]
  import PhoenixPaper.Menu, only: [pp_menu: 1, pp_menu_item: 1]

  attr(:id, :string,
    required: true,
    doc: "the root element's id; the rows-per-page menu derives its own from it"
  )

  attr(:page, :integer, required: true, doc: "the current page, 1-based")
  attr(:count, :integer, required: true, doc: "the total number of rows")
  attr(:rows_per_page, :integer, required: true)

  attr(:rows_per_page_options, :list,
    default: [10, 25, 50, 100],
    doc: "the page sizes offered; [] hides the picker"
  )

  attr(:path, :any,
    default: nil,
    doc: "a function (page, rows_per_page) -> URL; makes every control a link"
  )

  attr(:link, :string, default: "patch", values: ~w(patch navigate href))
  attr(:on_page_change, :any, default: nil, doc: "event for prev/next; sends phx-value-page")

  attr(:on_rows_per_page_change, :any,
    default: nil,
    doc: "event for the picker; sends phx-value-rows_per_page"
  )

  attr(:target, :any, default: nil, doc: "phx-target for the events")
  attr(:rows_per_page_label, :string, default: "Rows per page:")

  attr(:range_label, :any,
    default: nil,
    doc: "a function %{from, to, count} -> text; default \"1–10 of 47\""
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  @doc "Renders a table pagination bar. See the module doc."
  def pp_table_pagination(assigns) do
    %{page: page, count: count, rows_per_page: per_page} = assigns
    last_page = max(div(count + per_page - 1, per_page), 1)
    from = if count == 0, do: 0, else: (page - 1) * per_page + 1
    to = min(page * per_page, count)

    controls = [
      {:previous, page - 1, page <= 1},
      {:next, page + 1, page >= last_page}
    ]

    assigns =
      assign(assigns,
        controls: controls,
        displayed: displayed_rows(assigns.range_label, %{from: from, to: to, count: count})
      )

    ~H"""
    <div
      id={@id}
      data-pp-component="table-pagination"
      class={Helpers.classes(@paperize, "flex flex-wrap items-center justify-end gap-x-6 gap-y-2 px-4 py-2 pp-body-medium text-pp-on-surface-variant", @class)}
      {@rest}
    >
      <div :if={@rows_per_page_options != []} class="flex items-center gap-2">
        <span>{@rows_per_page_label}</span>
        <.pp_menu
          id={"#{@id}-rows-per-page"}
          anchor="top-end"
          trigger_variant="text"
          trigger_color="inherit"
          paperize={@paperize}
        >
          <:trigger>{@rows_per_page}</:trigger>
          <.rows_option
              :for={option <- @rows_per_page_options}
              option={option}
              selected={option == @rows_per_page}
              path={@path}
              link={@link}
              event={@on_rows_per_page_change}
              target={@target}
              paperize={@paperize}
            />
        </.pp_menu>
      </div>
      <span>{@displayed}</span>
      <div class="flex items-center gap-1">
        <.nav_button
          :for={{kind, to, off?} <- @controls}
          kind={kind}
          to={to}
          disabled={off?}
          url={is_function(@path, 2) && @path.(to, @rows_per_page)}
          link={@link}
          event={@on_page_change}
          target={@target}
          paperize={@paperize}
        />
      </div>
    </div>
    """
  end

  attr(:option, :integer, required: true)
  attr(:selected, :boolean, required: true)
  attr(:path, :any, required: true)
  attr(:link, :string, required: true)
  attr(:event, :any, required: true)
  attr(:target, :any, required: true)
  attr(:paperize, :boolean, required: true)

  defp rows_option(%{path: path} = assigns) when is_function(path, 2) do
    assigns = assign(assigns, link_attrs(assigns.link, path.(1, assigns.option)))

    ~H"""
    <.pp_menu_item
      href={@href}
      navigate={@navigate}
      patch={@patch}
      selected={@selected}
      paperize={@paperize}
    >
      {@option}
    </.pp_menu_item>
    """
  end

  defp rows_option(assigns) do
    ~H"""
    <.pp_menu_item
      selected={@selected}
      paperize={@paperize}
      phx-click={@event}
      phx-value-rows_per_page={@event && @option}
      phx-target={@event && @target}
    >
      {@option}
    </.pp_menu_item>
    """
  end

  attr(:kind, :atom, required: true)
  attr(:to, :integer, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:url, :any, required: true)
  attr(:link, :string, required: true)
  attr(:event, :any, required: true)
  attr(:target, :any, required: true)
  attr(:paperize, :boolean, required: true)

  defp nav_button(%{url: url, disabled: false} = assigns) when is_binary(url) do
    assigns = assign(assigns, link_attrs(assigns.link, url))

    ~H"""
    <.pp_icon_button
      icon={icon(@kind)}
      label={aria_label(@kind)}
      color="inherit"
      href={@href}
      navigate={@navigate}
      patch={@patch}
      paperize={@paperize}
    />
    """
  end

  defp nav_button(assigns) do
    ~H"""
    <.pp_icon_button
      icon={icon(@kind)}
      label={aria_label(@kind)}
      color="inherit"
      disabled={@disabled}
      paperize={@paperize}
      phx-click={!@disabled && @event}
      phx-value-page={!@disabled && @event && @to}
      phx-target={!@disabled && @event && @target}
    />
    """
  end

  defp link_attrs("href", url), do: [href: url, navigate: nil, patch: nil]
  defp link_attrs("navigate", url), do: [href: nil, navigate: url, patch: nil]
  defp link_attrs("patch", url), do: [href: nil, navigate: nil, patch: url]

  defp displayed_rows(nil, %{from: from, to: to, count: count}), do: "#{from}–#{to} of #{count}"
  defp displayed_rows(label, rows) when is_function(label, 1), do: label.(rows)

  defp icon(:previous), do: "hero-chevron-left"
  defp icon(:next), do: "hero-chevron-right"

  defp aria_label(:previous), do: "Go to previous page"
  defp aria_label(:next), do: "Go to next page"
end
