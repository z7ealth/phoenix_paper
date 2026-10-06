defmodule PhoenixPaper.Avatar do
  @moduledoc """
  An MD3 avatar (`pp_avatar/1`): the 40dp circle MD3 lists use as a
  leading element, holding a picture, initials or an icon.

      <.pp_avatar src="/images/remy.jpg" alt="Remy Sharp" />
      <.pp_avatar>RS</.pp_avatar>

      <.pp_list_item>
        <:leading><.pp_avatar>A</.pp_avatar></:leading>
        Ana
      </.pp_list_item>

  The look is MD3's: `primary-container` with `title-medium` initials in
  `on-primary-container`. A loaded image covers it completely.

  The `:inner_block` (initials, or an icon) is the fallback shown when
  there's no `src`, and it stays underneath the `<img>` when there is one:
  a small inline `onerror` hides a broken image, revealing the fallback —
  no LiveView round trip, no JS hook. With neither `src` nor
  `:inner_block` it falls back to a person icon.

  For several overlapping avatars, render them in a flex row with
  `-space-x-2` and give each `class="ring-2 ring-pp-surface"`.

  ## Migrating from 0.4

  `size`, `variant` and `color` are gone: MD3's avatar is one size, one
  shape and one color. Override with `!` classes (`class="!size-14"`) for
  a one-off, as for any built-in utility.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:src, :string, default: nil)
  attr(:alt, :string, default: "", doc: "for the <img>, when src is given")
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block,
    doc: "initials or an icon — the fallback shown with no src, or on image error"
  )

  @doc "Renders an avatar. See the module doc."
  def pp_avatar(assigns) do
    ~H"""
    <span
      data-pp-component="avatar"
      class={Helpers.classes(@paperize, avatar_classes(), @class)}
      {@rest}
    >
      <span
        :if={@inner_block != []}
        class="flex size-full select-none items-center justify-center leading-none"
      >
        {render_slot(@inner_block)}
      </span>
      <.pp_icon :if={@inner_block == []} name="hero-user" size="md" />
      <img
        :if={@src}
        src={@src}
        alt={@alt}
        onerror="this.style.display='none';"
        class="absolute inset-0 size-full object-cover"
      />
    </span>
    """
  end

  defp avatar_classes do
    "relative inline-flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-pp-full bg-pp-primary-container pp-title-medium text-pp-on-primary-container"
  end
end
