defmodule PhoenixPaper.ButtonGroup do
  @moduledoc """
  An M3 Expressive button group (`pp_button_group/1`) — lays out a row of
  `pp_button`s and/or `pp_icon_button`s and gives them the group's shape
  behavior. It replaces 0.3's `ToggleButton`/`ButtonGroup` pair and MD3's
  (now deprecated) segmented buttons.

  ## Variants

  - `standard` (default): spaced buttons. Pressing one widens it into the
    gap while its neighbors stay put — Expressive's "press expands"
    interaction, CSS only. Icon buttons, being fixed-width, only morph
    their corners.
  - `connected`: buttons 2dp apart sharing one pill outline — the outer
    corners fully round, the inner corners small, squeezing further on
    press. A selected (`aria-pressed`) button goes fully round. This is
    the replacement for segmented buttons.

  `size` must match the children's `size` (it picks the gap and the
  corner radii); HEEx can't push attrs into child components, so it isn't
  inherited — set both.

  ## Selection

  Selection lives on the buttons, via their toggle attrs (see
  `PhoenixPaper.Toggle`): give each button the same `group` for a
  single-select group, or plain `toggle` for multi-select.

      <.pp_button_group variant="connected" aria-label="View">
        <.pp_button variant="tonal" group="view" selected>Day</.pp_button>
        <.pp_button variant="tonal" group="view" selected={false}>Week</.pp_button>
        <.pp_button variant="tonal" group="view" selected={false}>Month</.pp_button>
      </.pp_button_group>

      <.pp_button_group aria-label="Text style">
        <.pp_icon_button icon="hero-bold" label="Bold" variant="tonal" toggle selected={false} />
        <.pp_icon_button icon="hero-italic" label="Italic" variant="tonal" toggle selected={false} />
      </.pp_button_group>

  Controlled groups (server-owned state) pass `selected={@view == "day"}`
  with a normal `phx-click` instead of `group`.

  `full_width` stretches the group to its container, buttons sharing the
  width equally — the usual layout for a connected group on mobile.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:variant, :string, default: "standard", values: ~w(standard connected))
  attr(:size, :string, default: "sm", values: ~w(xs sm md lg xl))
  attr(:full_width, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true)

  @doc "Renders a button group. See the module doc."
  def pp_button_group(assigns) do
    ~H"""
    <div
      role="group"
      data-pp-component="button-group"
      data-pp-variant={@variant}
      class={
        Helpers.classes(@paperize, paper_classes(@variant, @size, @full_width), @class)
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp paper_classes(variant, size, full_width) do
    [
      variant_classes(variant),
      size_vars(size),
      variant == "standard" && gap_classes(size),
      full_width && "flex w-full [&>*]:flex-1"
    ]
  end

  defp variant_classes("standard"), do: "pp-button-group-standard"
  defp variant_classes("connected"), do: "pp-button-group-connected"

  # Expressive standard-group spacing.
  defp gap_classes("xs"), do: "gap-[18px]"
  defp gap_classes("sm"), do: "gap-3"
  defp gap_classes(_size), do: "gap-2"

  # Outer (round) radius = half the height; inner and pressed-inner radii
  # from the Expressive connected-group spec; pad = the button's own
  # horizontal padding, which the standard group's press widening adds to.
  defp size_vars("xs"),
    do:
      "[--pp-group-outer:16px] [--pp-group-inner:4px] [--pp-group-pressed:2px] [--pp-group-pad:12px]"

  defp size_vars("sm"),
    do:
      "[--pp-group-outer:20px] [--pp-group-inner:8px] [--pp-group-pressed:4px] [--pp-group-pad:16px]"

  defp size_vars("md"),
    do:
      "[--pp-group-outer:28px] [--pp-group-inner:8px] [--pp-group-pressed:4px] [--pp-group-pad:24px]"

  defp size_vars("lg"),
    do:
      "[--pp-group-outer:48px] [--pp-group-inner:16px] [--pp-group-pressed:12px] [--pp-group-pad:48px]"

  defp size_vars("xl"),
    do:
      "[--pp-group-outer:68px] [--pp-group-inner:20px] [--pp-group-pressed:16px] [--pp-group-pad:64px]"
end
