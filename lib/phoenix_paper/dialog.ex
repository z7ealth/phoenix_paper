defmodule PhoenixPaper.Dialog do
  @moduledoc """
  A Material-styled modal dialog (`pp_dialog/1`), in the spirit of MUI's
  `Dialog` — but built the same way Phoenix's own `mix phx.new`-generated
  `core_components.ex` builds its `modal/1`: always present in the DOM,
  shown/hidden via `Phoenix.LiveView.JS` commands and CSS transitions, not a
  server-tracked `open` assign that re-renders the whole tree. If you've used
  that generated modal before, this is the same mechanism with Material
  chrome (`PhoenixPaper.Paper` for the surface, elevation, rounded corners)
  and `:title`/`:actions` slots instead of one opaque body.

      <.pp_button phx-click={PhoenixPaper.Dialog.show("confirm-delete")}>
        Delete
      </.pp_button>

      <.pp_dialog id="confirm-delete" on_cancel={JS.push("cancel_delete")}>
        <:title>Delete this item?</:title>
        This can't be undone.
        <:actions>
          <.pp_button variant="text" phx-click={PhoenixPaper.Dialog.hide("confirm-delete")}>
            Cancel
          </.pp_button>
          <.pp_button color="error" phx-click="confirm_delete">Delete</.pp_button>
        </:actions>
      </.pp_dialog>

  `show/1,2` and `hide/1,2` return `Phoenix.LiveView.JS` commands — wire them
  to whatever triggers open/close (a button elsewhere on the page, a form
  submit success, ...). `on_cancel` (default a no-op `%JS{}`) runs *in
  addition* to the built-in hide behavior when the backdrop is clicked or
  Escape is pressed — pass a `JS.push(...)` there if the server needs to know
  the dialog was dismissed this way (e.g. to reset form state), the same as
  the generated modal's own `on_cancel`.

  Uses `Phoenix.Component.focus_wrap/1` for tab-focus trapping — a built-in
  Phoenix accessibility helper (ships with `phoenix_live_view.js`'s
  `Phoenix.FocusWrap` hook), not a custom hook this library adds.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.Helpers

  import PhoenixPaper.Paper, only: [pp_paper: 1]

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false, doc: "shown immediately when this element first mounts")
  attr(:on_cancel, JS, default: %JS{})
  attr(:paperize, :boolean, default: true)

  attr(:elevation, :integer, default: 8)

  attr(:shape, :atom,
    default: :lg,
    values: ~w(none xs sm md lg xl full)a,
    doc: "corner radius token, see PhoenixPaper.Shape"
  )

  attr(:class, :any, default: nil)

  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Renders a dialog. See the module doc."
  def pp_dialog(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show(@id)}
      phx-remove={hide(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      data-pp-component="dialog"
      class="fixed inset-0 z-50 hidden"
    >
      <div id={"#{@id}-backdrop"} class="fixed inset-0 bg-black/50 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center p-4">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class="hidden"
          >
            <.pp_paper
              id={"#{@id}-content"}
              elevation={@elevation}
              shape={@shape}
              paperize={@paperize}
              component="dialog-content"
              class={Helpers.classes(@paperize, "w-full max-w-md p-6", @class)}
            >
              <div :if={@title != []} id={"#{@id}-title"} class="mb-2 text-lg font-medium">
                {render_slot(@title)}
              </div>
              {render_slot(@inner_block)}
              <div :if={@actions != []} class="mt-6 flex items-center justify-end gap-2">
                {render_slot(@actions)}
              </div>
            </.pp_paper>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command that shows the dialog with `id` — wire it
  to whatever should open it, e.g. `phx-click={PhoenixPaper.Dialog.show("my-dialog")}`
  on a button anywhere on the page.
  """
  def show(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}", transition: {"transition-opacity", "opacity-0", "opacity-100"})
    |> JS.show(
      to: "##{id}-container",
      display: "block",
      transition: {"transition-all transform", "opacity-0 scale-95", "opacity-100 scale-100"}
    )
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  A `Phoenix.LiveView.JS` command that hides the dialog with `id` — wire it
  to a "Cancel"/close button, e.g. inside the dialog's `:actions` slot.
  """
  def hide(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      transition: {"transition-opacity", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition: {"transition-all transform", "opacity-100 scale-100", "opacity-0 scale-95"}
    )
    |> JS.hide(to: "##{id}", time: 200)
    |> JS.pop_focus()
  end
end
