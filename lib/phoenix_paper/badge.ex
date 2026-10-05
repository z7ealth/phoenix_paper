defmodule PhoenixPaper.Badge do
  @moduledoc """
  An MD3 badge (`pp_badge/1`) on the corner of its child, usually an icon.

      <.pp_badge content={4}>
        <.pp_icon name="hero-bell" />
      </.pp_badge>

      <.pp_badge>
        <.pp_icon name="hero-chat-bubble-left" />
      </.pp_badge>

  MD3 has two badges, and `content` picks between them:

  - **Small** (no `content`): a 6dp dot that signals something new
    without a count.
  - **Large** (`content` set): a 16dp pill with `label-small` text,
    holding a count or a short label. An integer above `max` (default
    `999`, MD3's four-character limit) shows as `"\#{max}+"`; a string is
    shown as-is.

  Both use MD3's badge colors, `error` and `on-error`. A count of `0`
  hides the badge, and so does `invisible`.

  The wrapping `<span>`'s `relative inline-flex shrink-0` is structural and
  stays on under `paperize={false}`; the badge's own classes (size, color,
  position) are gated as usual.

  ## Migrating from 0.4

  `variant` is gone (no `content` is the small badge), and so are `color`,
  `overlap`, `anchor_origin` and `show_zero`: MD3 badges are always
  `error`-colored and sit on the child's top-end corner.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers

  attr(:content, :any,
    default: nil,
    doc: "a count or short label — nil renders the small (dot) badge"
  )

  attr(:max, :integer, default: 999, doc: "caps a numeric content at max+")
  attr(:invisible, :boolean, default: false, doc: "hide the badge")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block, required: true, doc: "the element the badge sits on")

  @doc "Renders a badge. See the module doc."
  def pp_badge(assigns) do
    ~H"""
    <span data-pp-component="badge" class="relative inline-flex shrink-0" {@rest}>
      {render_slot(@inner_block)}
      <span
        :if={!@invisible and @content != 0}
        data-pp-component="badge-dot"
        data-pp-size={if(is_nil(@content), do: "small", else: "large")}
        class={Helpers.classes(@paperize, badge_classes(is_nil(@content)), @class)}
      >
        {display_content(@content, @max)}
      </span>
    </span>
    """
  end

  defp display_content(content, max) when is_integer(content) and content > max, do: "#{max}+"
  defp display_content(content, _max), do: content

  defp badge_classes(small?) do
    [
      "pointer-events-none absolute z-10 flex items-center justify-center rounded-pp-full bg-pp-error text-pp-on-error",
      if(small?,
        do: "end-0 top-0 size-1.5",
        else: "start-1/2 top-0 h-4 min-w-4 -translate-y-1/4 px-1 pp-label-small"
      )
    ]
  end
end
