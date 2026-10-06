defmodule PhoenixPaper.PaneLayout do
  @moduledoc """
  MD3's canonical pane layouts: list-detail (`pp_list_detail/1`) and
  supporting pane (`pp_supporting_pane/1`).

  These come from MD3's Layout foundations rather than its component
  pages: window size classes, panes, margins and spacers. They follow
  that spec:

  - **Window size classes**: compact (under 600dp), medium (600–839dp)
    and expanded (840dp and up). Tailwind's default breakpoints don't
    match them, so the classes use literal `min-[600px]:`/`min-[840px]:`
    variants.
  - **Margins**: 16dp on compact, 24dp from medium up.
  - **Spacer** between panes: 24dp.
  - **Fixed pane width**: 360dp, for the list pane and the supporting
    pane when they sit beside a flexible pane.

  Panes are plain regions with no surface of their own: put a `pp_card`,
  a `pp_list` or anything else inside. Pair a layout with the app's
  navigation (`pp_navigation_rail`/`pp_navigation_bar`) beside it.

  ## List-detail

      <.pp_list_detail show_detail={@message != nil}>
        <:list>
          <.pp_list>
            <.pp_list_item :for={m <- @messages} patch={~p"/inbox/\#{m.id}"} active={m.id == @message_id}>
              {m.subject}
            </.pp_list_item>
          </.pp_list>
        </:list>
        <:detail>
          <.message :if={@message} message={@message} />
        </:detail>
      </.pp_list_detail>

  On expanded windows both panes show: the list at 360dp, the detail
  flexible. On compact and medium windows only one shows, as MD3
  recommends — the list, or the detail when `show_detail` is true. Going
  back is yours to render (e.g. a `pp_icon_button` in the detail that
  patches back to the list); this component is stateless and only
  decides which pane is visible.

  ## Supporting pane

      <.pp_supporting_pane>
        <article>...</article>
        <:supporting><.related_items items={@related} /></:supporting>
      </.pp_supporting_pane>

  On expanded windows the supporting pane sits beside the main content at
  360dp; on compact and medium windows it moves below it.

  Both layouts keep their structural classes under `paperize={false}`
  only for showing and hiding panes (`hidden`/`flex`); the margins,
  spacer and widths are dropped like any skin.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:show_detail, :boolean,
    default: false,
    doc: "compact and medium windows show the detail pane instead of the list"
  )

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:list, required: true, doc: "the list pane")
  slot(:detail, required: true, doc: "the detail pane")

  @doc "Renders MD3's list-detail layout. See the module doc."
  def pp_list_detail(assigns) do
    ~H"""
    <div
      data-pp-component="list-detail"
      data-pp-show-detail={to_string(@show_detail)}
      class={["flex min-h-0", Helpers.classes(@paperize, "gap-6 px-4 min-[600px]:px-6", @class)]}
      {@rest}
    >
      <div
        data-pp-pane="list"
        class={[
          list_visibility(@show_detail),
          Helpers.classes(@paperize, "min-w-0 flex-col min-[840px]:w-[360px] min-[840px]:shrink-0", nil)
        ]}
      >
        {render_slot(@list)}
      </div>
      <div
        data-pp-pane="detail"
        class={[detail_visibility(@show_detail), Helpers.classes(@paperize, "min-w-0 flex-1 flex-col", nil)]}
      >
        {render_slot(@detail)}
      </div>
    </div>
    """
  end

  # Compact/medium show one pane; expanded (840dp+) shows both.
  defp list_visibility(false), do: "flex w-full min-[840px]:w-auto"
  defp list_visibility(true), do: "hidden min-[840px]:flex"

  defp detail_visibility(false), do: "hidden min-[840px]:flex"
  defp detail_visibility(true), do: "flex"

  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the main (flexible) pane")
  slot(:supporting, required: true, doc: "the supporting pane")

  @doc "Renders MD3's supporting-pane layout. See the module doc."
  def pp_supporting_pane(assigns) do
    ~H"""
    <div
      data-pp-component="supporting-pane"
      class={[
        "flex flex-col min-[840px]:flex-row",
        Helpers.classes(@paperize, "gap-6 px-4 min-[600px]:px-6", @class)
      ]}
      {@rest}
    >
      <div data-pp-pane="main" class={Helpers.classes(@paperize, "min-w-0 flex-1", nil)}>
        {render_slot(@inner_block)}
      </div>
      <div
        data-pp-pane="supporting"
        class={Helpers.classes(@paperize, "min-w-0 min-[840px]:w-[360px] min-[840px]:shrink-0", nil)}
      >
        {render_slot(@supporting)}
      </div>
    </div>
    """
  end
end
