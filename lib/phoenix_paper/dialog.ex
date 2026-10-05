defmodule PhoenixPaper.Dialog do
  @moduledoc """
  An MD3 dialog (`pp_dialog/1`) — basic or full-screen — built the same way Phoenix's own `mix phx.new`-generated
  `core_components.ex` builds its `modal/1`: always present in the DOM,
  shown/hidden via `Phoenix.LiveView.JS` commands and CSS transitions, not a
  server-tracked `open` assign that re-renders the whole tree. If you've used
  that generated modal before, this is the same mechanism with MD3 chrome
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
          <.pp_button variant="text" phx-click="confirm_delete">Delete</.pp_button>
        </:actions>
      </.pp_dialog>

  `show/1,2` and `hide/1,2` return `Phoenix.LiveView.JS` commands — wire them
  to whatever triggers open/close (a button elsewhere on the page, a form
  submit success, ...). `on_cancel` (default a no-op `%JS{}`) runs *in
  addition* to the built-in hide behavior when the backdrop is clicked or
  Escape is pressed — pass a `JS.push(...)` there if the server needs to know
  the dialog was dismissed this way (e.g. to reset form state), the same as
  the generated modal's own `on_cancel`.

  ## Basic dialog

  A `surface-container-high` panel with 28dp corners and a level-3
  shadow over a 32% `scrim`. The title is `headline-small`, the body
  `body-medium` in `on-surface-variant`, and actions sit bottom-right —
  MD3 uses `text` buttons there. `icon` (a `hero-*` name) adds MD3's hero
  icon above the title, in `secondary`, which centers the title.

  ## Full-screen dialog

  `variant="fullscreen"` fills the viewport (MD3's full-screen dialog,
  for small screens or long tasks): a header row with a close icon button
  (`hide/2` plus `on_cancel`), the title and the `:actions` (usually one
  text button, "Save"), then the scrolling body. `variant="responsive"`
  is full-screen below `sm` and basic from `sm` up.

  ## `max_width`

  How wide a basic dialog can grow: `"xs"`, `"sm"`, `"md"`, `"lg"`
  (default — 32rem, close to MD3's 560dp maximum), `"xl"`, `"2xl"`, `"3xl"`, `"4xl"`,
  `"5xl"` (Tailwind's `max-w-*` scale, 20rem to 64rem) or `"full"` (the
  whole viewport width minus the 1rem margin). The dialog is always
  `w-full` up to that cap, so it still shrinks on small screens. Use this
  instead of a `class="!max-w-2xl"` override.

  The width and cap sit on the focus-wrap container (the element the
  centering flex row actually sizes), and the `Paper` panel fills it. With
  the cap on the panel instead (0.2.6), the container shrank to its
  content, so a `w-full` child with no natural width (a canvas, an empty
  input) collapsed to the text width, and long text widened the container
  past the panel, leaving the dialog off-centre. Under `paperize={false}`
  the container gets neither class and sizes to its content, as before.

      <.pp_dialog id="report" max_width="2xl">...</.pp_dialog>

  Uses `Phoenix.Component.focus_wrap/1` for tab-focus trapping — a built-in
  Phoenix accessibility helper (ships with `phoenix_live_view.js`'s
  `Phoenix.FocusWrap` hook), not a custom hook this library adds.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias PhoenixPaper.{Helpers, Icon}

  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]

  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false, doc: "shown immediately when this element first mounts")
  attr(:on_cancel, JS, default: %JS{})
  attr(:variant, :string, default: "basic", values: ~w(basic fullscreen responsive))
  attr(:icon, :string, default: nil, doc: "a hero-* icon above the title (basic dialogs)")
  attr(:close_label, :string, default: "Close", doc: "full-screen close button label")
  attr(:paperize, :boolean, default: true)

  attr(:max_width, :string,
    default: "lg",
    values: ~w(xs sm md lg xl 2xl 3xl 4xl 5xl full),
    doc: "a basic dialog's maximum width (Tailwind max-w-* scale)"
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
      data-pp-variant={@variant}
      class="fixed inset-0 z-50 hidden"
    >
      <div
        id={"#{@id}-backdrop"}
        class={["fixed inset-0 transition-opacity", @paperize && "bg-pp-scrim/32"]}
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class={wrapper_classes(@variant)}>
          <.focus_wrap
            id={"#{@id}-container"}
            phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
            phx-key="escape"
            phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
            class={["hidden", @paperize && container_classes(@variant, @max_width)]}
          >
            <div
              id={"#{@id}-content"}
              data-pp-component="dialog-content"
              class={Helpers.classes(@paperize, panel_classes(@variant), @class)}
            >
              <div
                :if={@variant != "basic"}
                class={["items-center gap-1 py-2 pe-4 ps-1", header_visibility(@variant)]}
              >
                <.pp_icon_button
                  icon="hero-x-mark"
                  label={@close_label}
                  paperize={@paperize}
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                />
                <div
                  id={@variant == "fullscreen" && "#{@id}-title"}
                  class={Helpers.classes(@paperize, "flex-1 truncate pp-title-large", nil)}
                >
                  {render_slot(@title)}
                </div>
                <div :if={@actions != []} class="flex items-center gap-2">
                  {render_slot(@actions)}
                </div>
              </div>

              <div class={basic_visibility(@variant)}>
                <Icon.pp_icon
                  :if={@icon}
                  name={@icon}
                  class={["mx-auto mb-4 block", @paperize && "text-pp-secondary"]}
                />
                <div
                  :if={@title != []}
                  id={@variant != "fullscreen" && "#{@id}-title"}
                  class={Helpers.classes(@paperize, ["mb-4 pp-headline-small text-pp-on-surface", @icon && "text-center"], nil)}
                >
                  {render_slot(@title)}
                </div>
              </div>

              <div class={Helpers.classes(@paperize, body_classes(@variant), nil)}>
                {render_slot(@inner_block)}
              </div>

              <div
                :if={@actions != []}
                class={["mt-6 flex flex-wrap items-center justify-end gap-2", basic_visibility(@variant)]}
              >
                {render_slot(@actions)}
              </div>
            </div>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A `Phoenix.LiveView.JS` command that shows the dialog with `id` — wire it
  to whatever should open it, e.g. `phx-click={PhoenixPaper.Dialog.show("my-dialog")}`
  on a button anywhere on the page. Enters with MD3's emphasized-decelerate
  curve: a short fade, scale and rise.
  """
  def show(js \\ %JS{}, id) do
    js
    |> JS.show(
      to: "##{id}",
      transition:
        {"transition-opacity duration-200 ease-pp-emphasized-decelerate", "opacity-0",
         "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "block",
      time: 400,
      transition:
        {"transition-all duration-400 ease-pp-emphasized-decelerate",
         "opacity-0 -translate-y-6 scale-95", "opacity-100 translate-y-0 scale-100"}
    )
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  A `Phoenix.LiveView.JS` command that hides the dialog with `id` — wire it
  to a "Cancel"/close button, e.g. inside the dialog's `:actions` slot.
  Exits with MD3's emphasized-accelerate curve.
  """
  def hide(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-backdrop",
      transition:
        {"transition-opacity duration-150 ease-pp-emphasized-accelerate", "opacity-100",
         "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 150,
      transition:
        {"transition-all duration-150 ease-pp-emphasized-accelerate",
         "opacity-100 translate-y-0 scale-100", "opacity-0 -translate-y-6 scale-95"}
    )
    |> JS.hide(to: "##{id}", time: 150)
    |> JS.pop_focus()
  end

  defp wrapper_classes("basic"), do: "flex min-h-full items-center justify-center p-6"
  defp wrapper_classes("fullscreen"), do: "flex min-h-full"

  defp wrapper_classes("responsive"),
    do: "flex min-h-full sm:items-center sm:justify-center sm:p-6"

  defp container_classes("basic", max_width),
    do: ["w-full min-w-[280px]", max_width_class(max_width)]

  defp container_classes("fullscreen", _max_width), do: "min-h-dvh w-full"

  defp container_classes("responsive", max_width),
    do: ["min-h-dvh w-full sm:min-h-0 sm:min-w-[280px]", responsive_max_width_class(max_width)]

  defp panel_classes("basic"),
    do: "w-full rounded-pp-xl bg-pp-surface-container-high p-6 text-pp-on-surface pp-elevation-3"

  defp panel_classes("fullscreen"),
    do: "flex min-h-dvh w-full flex-col bg-pp-surface text-pp-on-surface"

  defp panel_classes("responsive"),
    do:
      "flex min-h-dvh w-full flex-col bg-pp-surface text-pp-on-surface sm:block sm:min-h-0 sm:rounded-pp-xl sm:bg-pp-surface-container-high sm:p-6 sm:pp-elevation-3"

  defp header_visibility("fullscreen"), do: "flex"
  defp header_visibility("responsive"), do: "flex sm:hidden"

  defp basic_visibility("basic"), do: nil
  defp basic_visibility("fullscreen"), do: "hidden"
  defp basic_visibility("responsive"), do: "max-sm:hidden"

  defp body_classes("basic"), do: "pp-body-medium text-pp-on-surface-variant"
  defp body_classes("fullscreen"), do: "flex-1 overflow-y-auto px-6 pb-6 pp-body-medium"

  defp body_classes("responsive"),
    do: "flex-1 overflow-y-auto px-6 pb-6 pp-body-medium sm:p-0 sm:text-pp-on-surface-variant"

  defp max_width_class("xs"), do: "max-w-xs"
  defp max_width_class("sm"), do: "max-w-sm"
  defp max_width_class("md"), do: "max-w-md"
  defp max_width_class("lg"), do: "max-w-lg"
  defp max_width_class("xl"), do: "max-w-xl"
  defp max_width_class("2xl"), do: "max-w-2xl"
  defp max_width_class("3xl"), do: "max-w-3xl"
  defp max_width_class("4xl"), do: "max-w-4xl"
  defp max_width_class("5xl"), do: "max-w-5xl"
  defp max_width_class("full"), do: "max-w-full"

  defp responsive_max_width_class("xs"), do: "sm:max-w-xs"
  defp responsive_max_width_class("sm"), do: "sm:max-w-sm"
  defp responsive_max_width_class("md"), do: "sm:max-w-md"
  defp responsive_max_width_class("lg"), do: "sm:max-w-lg"
  defp responsive_max_width_class("xl"), do: "sm:max-w-xl"
  defp responsive_max_width_class("2xl"), do: "sm:max-w-2xl"
  defp responsive_max_width_class("3xl"), do: "sm:max-w-3xl"
  defp responsive_max_width_class("4xl"), do: "sm:max-w-4xl"
  defp responsive_max_width_class("5xl"), do: "sm:max-w-5xl"
  defp responsive_max_width_class("full"), do: "sm:max-w-full"
end
