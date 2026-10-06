defmodule PhoenixPaper.SideSheet do
  @moduledoc """
  An MD3 side sheet (`pp_side_sheet/1`) — modal or standard — for
  supplementary content and actions at the end edge of the screen (filters,
  details, settings).

      <.pp_button phx-click={PhoenixPaper.SideSheet.show("filters")}>Filters</.pp_button>

      <.pp_side_sheet id="filters">
        <:title>Filters</:title>
        <.pp_checkbox name="unread" label="Unread only" />
        <:actions>
          <.pp_button phx-click="apply_filters">Apply</.pp_button>
          <.pp_button variant="outlined" phx-click={PhoenixPaper.SideSheet.hide("filters")}>Cancel</.pp_button>
        </:actions>
      </.pp_side_sheet>

  ## Modal (default)

  Slides in from the end edge over a 32% `scrim`: a `surface-container-low`
  sheet, 16dp corners on its inner side, level-1 shadow, up to 400dp wide.
  A header row holds an optional back button (`on_back`), the `:title`
  (`title-large`) and a close icon button; `:actions` sit at the bottom
  behind a divider (MD3 puts a filled and an outlined button there). Same
  mechanism as `PhoenixPaper.Dialog`: always in the DOM, `show/2`/`hide/2`
  `JS` commands, focus trapping, Escape/scrim click dismiss (plus
  `on_cancel`).

  ## Standard

  `variant="standard"` renders in place as an `<aside>`: `surface` with an
  `outline-variant` divider on its start side, the same header/actions,
  no scrim, no close button unless you pass `on_close`. Lay it out
  beside your content (`flex`).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]

  attr(:id, :string, required: true)
  attr(:variant, :string, default: "modal", values: ~w(modal standard))
  attr(:show, :boolean, default: false, doc: "modal: shown when first mounted")
  attr(:on_cancel, JS, default: %JS{})
  attr(:on_back, :any, default: nil, doc: "a JS/event for a leading back button")
  attr(:on_close, :any, default: nil, doc: "standard sheets: a JS/event for a close button")
  attr(:close_label, :string, default: "Close")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders a side sheet. See the module doc."
  def pp_side_sheet(%{variant: "standard"} = assigns) do
    ~H"""
    <aside
      id={@id}
      aria-labelledby={@title != [] && "#{@id}-title"}
      data-pp-component="side-sheet"
      data-pp-variant="standard"
      class={Helpers.classes(@paperize, "flex w-[min(400px,100%)] shrink-0 flex-col border-s border-pp-outline-variant bg-pp-surface text-pp-on-surface", @class)}
    >
      {sheet_body(assigns)}
    </aside>
    """
  end

  def pp_side_sheet(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show(@id)}
      phx-remove={hide(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-pp-component="side-sheet"
      data-pp-variant="modal"
      class="fixed inset-0 z-50 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class={["fixed inset-0 transition-opacity", @paperize && "bg-pp-scrim/32"]}
        aria-hidden="true"
      />
      <.focus_wrap
        id={"#{@id}-container"}
        phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
        phx-key="escape"
        phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
        role="dialog"
        aria-modal="true"
        aria-labelledby={@title != [] && "#{@id}-title"}
        class={[
          "fixed inset-y-0 end-0 hidden",
          Helpers.classes(@paperize, "w-[min(400px,calc(100vw-3.5rem))] rounded-s-pp-lg bg-pp-surface-container-low text-pp-on-surface pp-elevation-1", @class)
        ]}
      >
        <div id={"#{@id}-content"} class="flex h-full flex-col">
          {sheet_body(assign(assigns, :on_close, JS.exec("data-cancel", to: "##{@id}")))}
        </div>
      </.focus_wrap>
    </div>
    """
  end

  defp sheet_body(assigns) do
    ~H"""
    <div class="flex min-h-[72px] items-center gap-1 ps-4 pe-3 pt-3 pb-4">
      <.pp_icon_button
        :if={@on_back}
        icon="hero-arrow-left"
        label="Back"
        class="-ms-2"
        phx-click={@on_back}
      />
      <h2
        :if={@title != []}
        id={"#{@id}-title"}
        class={Helpers.classes(@paperize, "flex-1 truncate pp-title-large text-pp-on-surface-variant", nil)}
      >
        {render_slot(@title)}
      </h2>
      <span :if={@title == []} class="flex-1" />
      <.pp_icon_button :if={@on_close} icon="hero-x-mark" label={@close_label} phx-click={@on_close} />
    </div>
    <div class="flex-1 overflow-y-auto px-6 pb-6">
      {render_slot(@inner_block)}
    </div>
    <div
      :if={@actions != []}
      class={Helpers.classes(@paperize, "flex flex-wrap items-center gap-2 border-t border-pp-outline-variant px-6 pt-4 pb-6", nil)}
    >
      {render_slot(@actions)}
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command showing the modal side sheet `id`: the
  scrim fades in and the sheet slides in from the end edge.
  """
  def show(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      transition:
        {"transition-opacity duration-200 ease-pp-emphasized-decelerate", "opacity-0",
         "opacity-100"}
    )
    # The scrim is hidden by hide/2, so show it again; the wrapper above
    # already fades it in, so it needs no transition of its own.
    |> JS.show(to: "##{id}-backdrop")
    |> JS.show(
      to: "##{id}-container",
      display: "block",
      time: 400,
      transition:
        {"transition-transform duration-400 ease-pp-emphasized-decelerate",
         "translate-x-full rtl:-translate-x-full", "translate-x-0"}
    )
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc "A `Phoenix.LiveView.JS` command hiding the modal side sheet `id`."
  def hide(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      transition:
        {"transition-opacity duration-200 ease-pp-emphasized-accelerate", "opacity-100",
         "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition:
        {"transition-transform duration-200 ease-pp-emphasized-accelerate", "translate-x-0",
         "translate-x-full rtl:-translate-x-full"}
    )
    |> JS.hide(to: "##{id}", time: 200)
    |> JS.pop_focus()
  end
end
