defmodule PhoenixPaper.BottomSheet do
  @moduledoc """
  An MD3 bottom sheet (`pp_bottom_sheet/1`) — modal or standard.

      <.pp_button phx-click={PhoenixPaper.BottomSheet.show("share")}>Share</.pp_button>

      <.pp_bottom_sheet id="share">
        <.pp_list>
          <.pp_list_item phx-click="copy_link">
            <:leading><.pp_icon name="hero-link" /></:leading>
            Copy link
          </.pp_list_item>
        </.pp_list>
      </.pp_bottom_sheet>

  ## Modal (default)

  Slides up from the bottom over a 32% `scrim`: a `surface-container-low`
  sheet, 28dp top corners, level-1 shadow, at most 640dp wide (centered
  on large screens) and 90% of the viewport tall, with MD3's drag handle
  on top. Built exactly like `PhoenixPaper.Dialog`: always in the DOM,
  `show/2`/`hide/2` `Phoenix.LiveView.JS` commands, `focus_wrap/1` for
  focus trapping, Escape/scrim click to dismiss (plus `on_cancel`). The
  handle is a button that dismisses too.

  With the PhoenixPaper JS hook (see `PhoenixPaper.Helpers.hook/1`) the sheet
  can be **dragged down** by its handle to dismiss, following the pointer
  and springing back if released early. (The hook sits on the handle, not
  the sheet: the sheet is a `focus_wrap/1`, which already carries
  LiveView's own focus-trap hook.)

  ## Standard

  `variant="standard"` is a sheet that coexists with the page: rendered
  in place (`show`/`hide` don't apply), `surface-container-low`, 28dp top
  corners, no scrim — for persistent supplementary content docked to the
  bottom of a layout (`class="fixed inset-x-0 bottom-0"`, or in flow).
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  attr(:id, :string, required: true)
  attr(:variant, :string, default: "modal", values: ~w(modal standard))
  attr(:show, :boolean, default: false, doc: "modal: shown when first mounted")
  attr(:on_cancel, JS, default: %JS{})
  attr(:drag_handle, :boolean, default: true)
  attr(:label, :string, default: nil, doc: "aria-label of the sheet")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)

  slot(:inner_block, required: true)

  @doc "Renders a bottom sheet. See the module doc."
  def pp_bottom_sheet(%{variant: "standard"} = assigns) do
    ~H"""
    <section
      id={@id}
      aria-label={@label}
      data-pp-component="bottom-sheet"
      data-pp-variant="standard"
      class={Helpers.classes(@paperize, "rounded-t-pp-xl bg-pp-surface-container-low px-4 pb-6 text-pp-on-surface pp-elevation-1", @class)}
    >
      <div :if={@drag_handle && @paperize} class="flex justify-center py-4">
        <span class="h-1 w-8 rounded-full bg-pp-on-surface-variant/40" />
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  def pp_bottom_sheet(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show(@id)}
      phx-remove={hide(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-pp-component="bottom-sheet"
      data-pp-variant="modal"
      class="fixed inset-0 z-50 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class={["fixed inset-0 transition-opacity", @paperize && "bg-pp-scrim/32"]}
        aria-hidden="true"
      />
      <div class="fixed inset-x-0 bottom-0 flex justify-center">
        <.focus_wrap
          id={"#{@id}-container"}
          phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
          phx-key="escape"
          phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
          role="dialog"
          aria-modal="true"
          aria-label={@label}
          data-pp-sheet="bottom"
          class={[
            "hidden w-full",
            Helpers.classes(@paperize, sheet_classes(), @class)
          ]}
        >
          <button
            :if={@drag_handle && @paperize}
            type="button"
            id={"#{@id}-handle"}
            phx-hook={Helpers.hook()}
            data-pp-sheet-handle
            aria-label="Dismiss"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
            class="flex w-full cursor-grab touch-none justify-center py-4 focus-visible:outline-none [&:focus-visible>span]:outline-3 [&:focus-visible>span]:outline-offset-2 [&:focus-visible>span]:outline-solid [&:focus-visible>span]:outline-pp-secondary"
          >
            <span class="h-1 w-8 rounded-full bg-pp-on-surface-variant/40" />
          </button>
          <div id={"#{@id}-content"} class="max-h-[calc(90dvh-3rem)] overflow-y-auto px-4 pb-6">
            {render_slot(@inner_block)}
          </div>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command showing the modal sheet `id`: the scrim
  fades in and the sheet rises on MD3's emphasized-decelerate curve.
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
        {"transition-transform duration-400 ease-pp-emphasized-decelerate", "translate-y-full",
         "translate-y-0"}
    )
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc "A `Phoenix.LiveView.JS` command hiding the modal sheet `id`."
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
        {"transition-transform duration-200 ease-pp-emphasized-accelerate", "translate-y-0",
         "translate-y-full"}
    )
    |> JS.hide(to: "##{id}", time: 200)
    |> JS.pop_focus()
  end

  defp sheet_classes,
    do:
      "max-w-[640px] rounded-t-pp-xl bg-pp-surface-container-low text-pp-on-surface pp-elevation-1"
end
