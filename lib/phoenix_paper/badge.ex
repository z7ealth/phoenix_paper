defmodule PhoenixPaper.Badge do
  @moduledoc """
  A small count/status indicator overlapping the corner of its child
  (`pp_badge/1`), in the spirit of MUI's `Badge`.

      <.pp_badge content={4}>
        <.pp_icon name="hero-bell" />
      </.pp_badge>

      <.pp_badge variant="dot" color="success">
        <.pp_icon name="hero-user" />
      </.pp_badge>

  `content` is rendered as-is, except when it's an integer greater than
  `max` (default `99`), which renders as `"\#{max}+"` — the same
  `badgeContent`/`max` behavior as MUI's `Badge`, and only for integers;
  a string `content` is never truncated.

  The badge is automatically hidden (nothing rendered but the child) when:

  - `invisible={true}` is passed explicitly, or
  - `content` is the integer `0` and `show_zero` is `false` (the default),
    or
  - `content` is `nil` and `variant` is `"standard"` (there's nothing to
    show).

  A `variant="dot"` badge with no `content` stays visible (a blank colored
  dot, e.g. an "online" status indicator) — only the `0`/`show_zero` rule
  above can hide it, matching MUI's own `Badge` exactly (including the
  perhaps-surprising case of a `dot` badge with `content={0}`, which is
  still hidden unless `show_zero` is set).

  `overlap` (`"rectangular"` default, or `"circular"`) pulls the badge
  further inward for a circular child (e.g. an avatar) so it still reads as
  overlapping the visible circle instead of floating off past its corner —
  the same distinction MUI's `overlap` prop makes; `anchor_origin` (default
  `"top-right"`) picks which corner.

  Deliberately no `color="default"` (MUI's own default): every other color
  attr in this library is `primary`/`secondary`/`tertiary`/`error` plus
  `success`/`warning`/`info` for status (see `PhoenixPaper.Alert`) — adding
  an eighth, gray "default" here just for `Badge` would be a new token this
  library otherwise never needs. `color` defaults to `"error"` instead,
  since an unread/notification count (the most common real-world `Badge`)
  reads immediately as attention-grabbing red — pass `color="primary"` (or
  any other token) for a neutral count.

  The wrapping `<span>`'s `relative inline-flex shrink-0` is not gated by
  `paperize` — like `Autocomplete`'s dropdown-anchor wrapper (see
  AGENTS.md), it's the minimum structure the badge needs to position itself
  at all, not part of the "paper" skin. `paperize={false}` still drops
  every class from the badge dot/pill itself (size, color, absolute
  position, everything) — same all-or-nothing contract as everywhere else,
  meaning a `paperize={false}` badge needs its own `class` to be positioned
  and colored at all (compare `PhoenixPaper.Snackbar`'s `paperize={false}`,
  which has the same trade-off for the same reason).
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:content, :any,
    default: nil,
    doc: "badge content — a number or short string; nil renders nothing unless variant=\"dot\""
  )

  attr(:max, :integer, default: 99, doc: "caps a numeric content at max+, e.g. 99+")

  attr(:show_zero, :boolean,
    default: false,
    doc: "show the badge when content is the integer 0"
  )

  attr(:variant, :string, default: "standard", values: ~w(standard dot))

  attr(:color, :string,
    default: "error",
    values: ~w(primary secondary tertiary error success warning info)
  )

  attr(:overlap, :string,
    default: "rectangular",
    values: ~w(rectangular circular),
    doc: "pulls the badge inward to sit on a circular child, e.g. an avatar"
  )

  attr(:anchor_origin, :string,
    default: "top-right",
    values: ~w(top-right top-left bottom-right bottom-left)
  )

  attr(:invisible, :boolean, default: false, doc: "force-hide the badge regardless of content")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the element the badge overlaps")

  @doc "Renders a badge. See the module doc."
  def pp_badge(assigns) do
    ~H"""
    <span data-pp-component="badge" class="relative inline-flex shrink-0" {@rest}>
      {render_slot(@inner_block)}
      <span
        :if={!hidden?(@invisible, @content, @show_zero, @variant)}
        data-pp-component="badge-dot"
        class={Helpers.classes(@paperize, badge_classes(@variant, @color, @overlap, @anchor_origin), @class)}
      >
        {display_content(@variant, @content, @max)}
      </span>
    </span>
    """
  end

  defp hidden?(invisible, content, show_zero, variant) do
    invisible or (content == 0 and not show_zero) or (is_nil(content) and variant == "standard")
  end

  defp display_content("dot", _content, _max), do: nil

  defp display_content(_variant, content, max) when is_integer(content) and content > max,
    do: "#{max}+"

  defp display_content(_variant, content, _max), do: content

  defp badge_classes(variant, color, overlap, anchor_origin) do
    [
      "pointer-events-none absolute z-10 flex items-center justify-center rounded-full font-medium leading-none",
      variant_size_classes(variant),
      color_classes(color),
      position_classes(anchor_origin, overlap)
    ]
  end

  defp variant_size_classes("dot"), do: "size-1.5"
  defp variant_size_classes("standard"), do: "h-5 min-w-5 px-1.5 text-xs"

  defp color_classes("primary"), do: "bg-pp-primary text-pp-on-primary"
  defp color_classes("secondary"), do: "bg-pp-secondary text-pp-on-secondary"
  defp color_classes("tertiary"), do: "bg-pp-tertiary text-pp-on-tertiary"
  defp color_classes("error"), do: "bg-pp-error text-pp-on-error"
  defp color_classes("success"), do: "bg-pp-success text-pp-on-success"
  defp color_classes("warning"), do: "bg-pp-warning text-pp-on-warning"
  defp color_classes("info"), do: "bg-pp-info text-pp-on-info"

  defp position_classes("top-right", "rectangular"),
    do: "top-0 right-0 translate-x-1/2 -translate-y-1/2"

  defp position_classes("top-right", "circular"),
    do: "top-[14%] right-[14%] translate-x-1/2 -translate-y-1/2"

  defp position_classes("top-left", "rectangular"),
    do: "top-0 left-0 -translate-x-1/2 -translate-y-1/2"

  defp position_classes("top-left", "circular"),
    do: "top-[14%] left-[14%] -translate-x-1/2 -translate-y-1/2"

  defp position_classes("bottom-right", "rectangular"),
    do: "bottom-0 right-0 translate-x-1/2 translate-y-1/2"

  defp position_classes("bottom-right", "circular"),
    do: "bottom-[14%] right-[14%] translate-x-1/2 translate-y-1/2"

  defp position_classes("bottom-left", "rectangular"),
    do: "bottom-0 left-0 -translate-x-1/2 translate-y-1/2"

  defp position_classes("bottom-left", "circular"),
    do: "bottom-[14%] left-[14%] -translate-x-1/2 translate-y-1/2"
end
