defmodule PhoenixPaper.SplitButton do
  @moduledoc """
  An M3 Expressive split button (`pp_split_button/1`): a primary action
  joined to a trailing button that opens a menu of related actions.

      <.pp_split_button id="send" phx-click="send">
        Send
        <:menu>
          <.pp_menu_item icon="hero-clock" phx-click="schedule">Schedule send</.pp_menu_item>
          <.pp_menu_item icon="hero-document" phx-click="save_draft">Save draft</.pp_menu_item>
        </:menu>
      </.pp_split_button>

  The two halves sit 2dp apart: the outer corners fully round, the inner
  corners small. Opening the menu morphs the trailing half into a full
  circle and flips its chevron, on the Expressive spatial spring.

  `variant` is `filled` (default), `tonal`, `elevated` or `outlined`;
  `size` is `xs`..`xl`, like `PhoenixPaper.Button`; `color` swaps the role.
  `phx-click` and the rest of the global attrs go on the leading button;
  `:start_icon` puts an icon in it. The menu panel and items are
  `PhoenixPaper.Menu`'s (`pp_menu_item/1`), with the same open/close
  behavior; `menu_label` names the trailing button.
  """
  use Phoenix.Component

  alias PhoenixPaper.{Button, Helpers, Icon, Menu, Ripple}

  attr(:id, :string, required: true)
  attr(:variant, :string, default: "filled", values: ~w(filled tonal elevated outlined))
  attr(:color, :string, default: nil, values: [nil | ~w(primary secondary tertiary error)])
  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl))

  attr(:anchor, :string,
    default: "bottom-end",
    values: ~w(bottom-start bottom-end top-start top-end)
  )

  attr(:menu_label, :string, default: "More options")
  attr(:disabled, :boolean, default: false)
  attr(:type, :string, default: "button", values: ~w(button submit reset))
  attr(:ripple, :boolean, default: true)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(form name value))

  slot(:start_icon)
  slot(:inner_block, required: true, doc: "the leading button's label")
  slot(:menu, required: true, doc: "the menu's pp_menu_item/1s")

  @doc "Renders a split button. See the module doc."
  def pp_split_button(assigns) do
    assigns =
      assigns
      |> assign(:ripple?, assigns.ripple and assigns.paperize and not assigns.disabled)
      |> assign(:color_role, assigns.color || Button.default_color(assigns.variant))

    ~H"""
    <div
      id={@id}
      phx-hook={Helpers.hook(@id)}
      data-pp-component="split-button"
      class={["relative inline-flex gap-0.5", @class]}
    >
      <button
        type={@type}
        disabled={@disabled}
        class={Helpers.classes(@paperize, leading_classes(@variant, @color_role, @size), nil)}
        onclick={Ripple.on_click(@ripple?)}
        {@rest}
      >
        <span :if={@start_icon != []} class="inline-flex shrink-0">{render_slot(@start_icon)}</span>
        {render_slot(@inner_block)}
      </button>
      <button
        type="button"
        id={"#{@id}-trigger"}
        disabled={@disabled}
        aria-label={@menu_label}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={"#{@id}-panel"}
        phx-click={Menu.toggle(@id)}
        onclick={Ripple.on_click(@ripple?)}
        class={Helpers.classes(@paperize, trailing_classes(@variant, @color_role, @size), nil)}
      >
        <Icon.pp_icon
          name="hero-chevron-down"
          size="none"
          class="size-[1.15em] pp-motion-spatial-fast [[aria-expanded=true]>&]:rotate-180"
        />
      </button>
      <div
        id={"#{@id}-panel"}
        phx-click-away={Menu.close(@id)}
        phx-window-keydown={Menu.close(@id)}
        phx-key="escape"
        phx-click={Menu.close(@id)}
        role="menu"
        aria-labelledby={"#{@id}-trigger"}
        data-pp-component="menu-panel"
        data-pp-color="standard"
        class={[
          "group/menu absolute z-40 hidden",
          anchor_classes(@anchor),
          Helpers.classes(
            @paperize,
            "min-w-[112px] max-w-[280px] w-max flex-col gap-0.5 rounded-pp-lg bg-pp-surface-container p-1 text-pp-on-surface pp-elevation-2",
            nil
          )
        ]}
      >
        {render_slot(@menu)}
      </div>
    </div>
    """
  end

  defp common(variant, color) do
    [
      "relative inline-flex shrink-0 items-center justify-center overflow-hidden whitespace-nowrap cursor-pointer select-none pp-state-layer pp-focus-ring pp-motion-spatial-fast disabled:cursor-default disabled:pointer-events-none",
      Button.color_classes(variant, color),
      Button.disabled_classes(variant)
    ]
  end

  defp leading_classes(variant, color, size),
    do: [common(variant, color), Button.size_classes(size), leading_shape(size)]

  defp trailing_classes(variant, color, size),
    do: [common(variant, color), trailing_size(size), trailing_shape(size)]

  # Outer corners: half the height. Inner corners: Expressive's small
  # radius, growing a little on press.
  defp leading_shape("xs"), do: "rounded-s-[16px] rounded-e-[4px] active:rounded-e-pp-sm"
  defp leading_shape("sm"), do: "rounded-s-[20px] rounded-e-[4px] active:rounded-e-pp-sm"
  defp leading_shape("md"), do: "rounded-s-[28px] rounded-e-[4px] active:rounded-e-pp-md"
  defp leading_shape("lg"), do: "rounded-s-[48px] rounded-e-pp-sm active:rounded-e-pp-lg"
  defp leading_shape("xl"), do: "rounded-s-[68px] rounded-e-pp-md active:rounded-e-pp-lg"

  # Open (aria-expanded): the trailing half becomes a full circle/pill.
  defp trailing_shape("xs"),
    do: "rounded-s-[4px] rounded-e-[16px] aria-expanded:rounded-[16px]"

  defp trailing_shape("sm"),
    do: "rounded-s-[4px] rounded-e-[20px] aria-expanded:rounded-[20px]"

  defp trailing_shape("md"),
    do: "rounded-s-[4px] rounded-e-[28px] aria-expanded:rounded-[28px]"

  defp trailing_shape("lg"),
    do: "rounded-s-pp-sm rounded-e-[48px] aria-expanded:rounded-[48px]"

  defp trailing_shape("xl"),
    do: "rounded-s-pp-md rounded-e-[68px] aria-expanded:rounded-[68px]"

  defp trailing_size("xs"), do: "h-8 px-1.5 text-[20px]"
  defp trailing_size("sm"), do: "h-10 px-2.5 text-[22px]"
  defp trailing_size("md"), do: "h-14 px-4 text-[24px]"
  defp trailing_size("lg"), do: "h-24 px-7 text-[32px]"
  defp trailing_size("xl"), do: "h-[8.5rem] px-10 text-[40px]"

  defp anchor_classes("bottom-start"), do: "top-full start-0 mt-1"
  defp anchor_classes("bottom-end"), do: "top-full end-0 mt-1"
  defp anchor_classes("top-start"), do: "bottom-full start-0 mb-1"
  defp anchor_classes("top-end"), do: "bottom-full end-0 mb-1"
end
