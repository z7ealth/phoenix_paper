defmodule PhoenixPaper.SearchBar do
  @moduledoc """
  An MD3 search bar (`pp_search_bar/1`), with an optional docked search
  view for suggestions/results.

      <form phx-change="search" phx-submit="search">
        <.pp_search_bar name="q" value={@q} placeholder="Search mail" phx-debounce="300">
          <:trailing><.pp_avatar src={@current_user.avatar} size="small" /></:trailing>
          <:results>
            <.pp_list>
              <.pp_list_item :for={hit <- @hits} navigate={hit.path}>{hit.title}</.pp_list_item>
            </.pp_list>
          </:results>
        </.pp_search_bar>
      </form>

  A 56dp, fully rounded `surface-container-high` bar with a leading search
  icon (or your `:leading` slot — a menu/back icon button), the input in
  `body-large`, and a `:trailing` slot (icon buttons, an avatar).

  ## Search view

  Given `:results`, the bar opens into MD3's **docked search view** while
  it has focus: its bottom corners square off and a `surface-container-high`
  panel (28dp bottom corners, level-3 shadow) drops down with the results,
  separated by an `outline-variant` divider. Pure CSS — the panel shows on
  `:focus-within`, so tabbing or clicking into a result keeps it open;
  Escape blurs the input and closes it. Render the results from your
  LiveView as the query changes (the input is a plain named input: put it
  in a form with `phx-change`, or give it `phx-keyup`). `results_open`
  keeps the view open regardless of focus.

  `full_width` stretches the bar (a docked view always matches the bar's
  width).

  ## Full-screen search view

  `view="fullscreen"` is MD3's full-screen search view: while the input has
  focus, the bar and results lift into a fixed, full-viewport
  `surface-container-high` layer — the bar becomes a 72dp header with a
  divider, the search icon becomes a back button (it blurs the input,
  which closes the view), and the results fill the rest. Still CSS only
  (`:focus-within`); an in-flow placeholder keeps the bar's space so the
  page doesn't jump. `view="responsive"` is full screen below `sm` and
  docked from `sm` up — MD3's recommendation for compact vs. larger
  windows.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:id, :string, default: nil)
  attr(:name, :string, default: "q")
  attr(:value, :string, default: nil)
  attr(:placeholder, :string, default: "Search")
  attr(:label, :string, default: nil, doc: "aria-label; defaults to the placeholder")
  attr(:full_width, :boolean, default: false)

  attr(:view, :string,
    default: "docked",
    values: ~w(docked fullscreen responsive),
    doc:
      "the search view while focused: docked under the bar, full screen, or full screen below sm"
  )

  attr(:back_label, :string, default: "Back", doc: "full-screen view's back button label")
  attr(:results_open, :boolean, default: false, doc: "keep the search view open")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  attr(:rest, :global,
    include: ~w(autocomplete autofocus form list maxlength minlength pattern readonly required)
  )

  slot(:leading, doc: "replaces the search icon (a menu or back icon button)")
  slot(:trailing, doc: "trailing icon buttons or an avatar")
  slot(:results, doc: "the docked search view's content, shown while focused")

  @escape_js "if(event.key==='Escape'){this.blur();}"

  @doc "Renders a search bar. See the module doc."
  def pp_search_bar(assigns) do
    assigns = assign(assigns, :escape_js, @escape_js)

    ~H"""
    <div
      data-pp-component="search-bar"
      data-pp-view={@view}
      class={["relative h-14", if(@full_width, do: "w-full", else: "w-full max-w-[720px]"), @class]}
    >
      <div
        data-pp-open={@results_open}
        class={["group/search", Helpers.classes(@paperize, panel_classes(@view), nil)]}
      >
        <div class={Helpers.classes(@paperize, bar_classes(@view, @results != []), nil)}>
          <span :if={@leading != []} class={leading_classes(@view)}>{render_slot(@leading)}</span>
          <span
            :if={@leading == []}
            class={["flex size-12 shrink-0 items-center justify-center text-pp-on-surface", leading_classes(@view)]}
          >
            <.pp_icon name="hero-magnifying-glass" />
          </span>
          <button
            :if={@view != "docked"}
            type="button"
            aria-label={@back_label}
            onclick="this.blur()"
            class={["size-12 shrink-0 cursor-pointer items-center justify-center rounded-full text-pp-on-surface", back_classes(@view)]}
          >
            <.pp_icon name="hero-arrow-left" />
          </button>
          <input
            type="search"
            id={@id}
            name={@name}
            value={@value}
            placeholder={@placeholder}
            aria-label={@label || @placeholder}
            role={@results != [] && "combobox"}
            aria-expanded={@results != [] && to_string(@results_open)}
            aria-controls={@results != [] && @id && "#{@id}-results"}
            autocomplete="off"
            onkeydown={@escape_js}
            class={Helpers.classes(@paperize, "h-full min-w-0 flex-1 bg-transparent pp-body-large text-pp-on-surface outline-none placeholder:text-pp-on-surface-variant [&::-webkit-search-cancel-button]:appearance-none", nil)}
            {@rest}
          />
          <span :if={@trailing != []} class="flex shrink-0 items-center gap-1">
            {render_slot(@trailing)}
          </span>
        </div>
        <div
          :if={@results != []}
          id={@id && "#{@id}-results"}
          class={Helpers.classes(@paperize, view_classes(@view), nil)}
        >
          {render_slot(@results)}
        </div>
      </div>
    </div>
    """
  end

  # The panel holds bar + results. Docked, it's in flow. Full screen, it
  # lifts into a fixed `surface-container-high` layer while focused (or
  # `results_open`); the outer `h-14` box keeps the bar's space so the
  # page doesn't jump.
  defp panel_classes("docked"), do: "relative"

  defp panel_classes("fullscreen"),
    do:
      "relative focus-within:fixed focus-within:inset-0 focus-within:z-50 focus-within:flex focus-within:flex-col focus-within:bg-pp-surface-container-high data-pp-open:fixed data-pp-open:inset-0 data-pp-open:z-50 data-pp-open:flex data-pp-open:flex-col data-pp-open:bg-pp-surface-container-high"

  defp panel_classes("responsive"),
    do:
      "relative max-sm:focus-within:fixed max-sm:focus-within:inset-0 max-sm:focus-within:z-50 max-sm:focus-within:flex max-sm:focus-within:flex-col max-sm:focus-within:bg-pp-surface-container-high max-sm:data-pp-open:fixed max-sm:data-pp-open:inset-0 max-sm:data-pp-open:z-50 max-sm:data-pp-open:flex max-sm:data-pp-open:flex-col max-sm:data-pp-open:bg-pp-surface-container-high"

  # Full screen: the search icon gives way to a back button that blurs the
  # input, which closes the view.
  defp leading_classes("docked"), do: "flex shrink-0 items-center"

  defp leading_classes("fullscreen"),
    do:
      "flex shrink-0 items-center group-focus-within/search:hidden group-data-pp-open/search:hidden"

  defp leading_classes("responsive"),
    do:
      "flex shrink-0 items-center max-sm:group-focus-within/search:hidden max-sm:group-data-pp-open/search:hidden"

  defp back_classes("fullscreen"),
    do:
      "hidden group-focus-within/search:inline-flex group-data-pp-open/search:inline-flex pp-state-layer relative overflow-hidden"

  defp back_classes("responsive"),
    do:
      "hidden max-sm:group-focus-within/search:inline-flex max-sm:group-data-pp-open/search:inline-flex pp-state-layer relative overflow-hidden"

  # With a docked search view, the bar's bottom corners square off while
  # open so bar and panel read as one surface. Full screen, the open bar
  # becomes a 72dp header with a divider.
  defp bar_classes(view, results?) do
    [
      "relative z-30 flex h-14 items-center gap-1 rounded-[28px] bg-pp-surface-container-high px-1 pe-4 pp-motion-spatial-fast",
      docked_open(view, results?),
      fullscreen_open(view)
    ]
  end

  defp docked_open("docked", true),
    do: "group-focus-within/search:rounded-b-none group-data-pp-open/search:rounded-b-none"

  defp docked_open("responsive", true),
    do: "sm:group-focus-within/search:rounded-b-none sm:group-data-pp-open/search:rounded-b-none"

  defp docked_open(_view, _results?), do: nil

  defp fullscreen_open("fullscreen"),
    do:
      "group-focus-within/search:h-[72px] group-focus-within/search:shrink-0 group-focus-within/search:rounded-none group-focus-within/search:border-b group-focus-within/search:border-pp-outline-variant group-data-pp-open/search:h-[72px] group-data-pp-open/search:rounded-none group-data-pp-open/search:border-b group-data-pp-open/search:border-pp-outline-variant"

  defp fullscreen_open("responsive"),
    do:
      "max-sm:group-focus-within/search:h-[72px] max-sm:group-focus-within/search:shrink-0 max-sm:group-focus-within/search:rounded-none max-sm:group-focus-within/search:border-b max-sm:group-focus-within/search:border-pp-outline-variant max-sm:group-data-pp-open/search:h-[72px] max-sm:group-data-pp-open/search:rounded-none max-sm:group-data-pp-open/search:border-b max-sm:group-data-pp-open/search:border-pp-outline-variant"

  defp fullscreen_open("docked"), do: nil

  defp view_classes("docked") do
    [
      "absolute inset-x-0 top-full z-30 max-h-[min(60vh,560px)] overflow-y-auto rounded-b-[28px] border-t border-pp-outline-variant bg-pp-surface-container-high pb-2 text-pp-on-surface pp-elevation-3",
      "invisible -translate-y-2 opacity-0 pp-motion-spatial-fast",
      "group-focus-within/search:visible group-focus-within/search:translate-y-0 group-focus-within/search:opacity-100",
      "group-data-pp-open/search:visible group-data-pp-open/search:translate-y-0 group-data-pp-open/search:opacity-100"
    ]
  end

  # Full screen: the results fill the rest of the layer, in flow.
  defp view_classes("fullscreen") do
    [
      "hidden text-pp-on-surface",
      "group-focus-within/search:block group-focus-within/search:flex-1 group-focus-within/search:overflow-y-auto",
      "group-data-pp-open/search:block group-data-pp-open/search:flex-1 group-data-pp-open/search:overflow-y-auto"
    ]
  end

  # Responsive: full screen below sm, docked from sm up.
  defp view_classes("responsive") do
    [
      "text-pp-on-surface",
      "max-sm:hidden max-sm:group-focus-within/search:block max-sm:group-focus-within/search:flex-1 max-sm:group-focus-within/search:overflow-y-auto max-sm:group-data-pp-open/search:block max-sm:group-data-pp-open/search:flex-1 max-sm:group-data-pp-open/search:overflow-y-auto",
      "sm:absolute sm:inset-x-0 sm:top-full sm:z-30 sm:max-h-[min(60vh,560px)] sm:overflow-y-auto sm:rounded-b-[28px] sm:border-t sm:border-pp-outline-variant sm:bg-pp-surface-container-high sm:pb-2 sm:pp-elevation-3",
      "sm:invisible sm:-translate-y-2 sm:opacity-0 pp-motion-spatial-fast",
      "sm:group-focus-within/search:visible sm:group-focus-within/search:translate-y-0 sm:group-focus-within/search:opacity-100",
      "sm:group-data-pp-open/search:visible sm:group-data-pp-open/search:translate-y-0 sm:group-data-pp-open/search:opacity-100"
    ]
  end
end
