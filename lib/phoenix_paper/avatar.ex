defmodule PhoenixPaper.Avatar do
  @moduledoc """
  A user's profile picture, initials, or icon (`pp_avatar/1`), in the
  spirit of MUI's `Avatar`.

      <.pp_avatar src="/images/1.jpg" alt="Remy Sharp" />
      <.pp_avatar>OP</.pp_avatar>
      <.pp_avatar size="large" variant="rounded">
        <.pp_icon name="hero-home" />
      </.pp_avatar>

  The `:inner_block` slot (initials, or an icon) is the fallback shown
  whenever there's no `src`, **and** stays ready underneath the `<img>`
  when there is one: a small vanilla `onerror` (same "small snippet, no
  hook" precedent as `PhoenixPaper.Ripple`) just sets the broken image's
  own `display:none`, revealing the fallback beneath it — no LiveView
  round-trip, no JS hook, matching MUI's own broken-image-falls-back-to-
  children behavior without needing an `onError` callback wired up
  server-side. Give no `src` and no `:inner_block` and it falls back
  further still, to a generic person icon — MUI's own default `Avatar`
  fallback.

  `size` (`"small"`/`"medium"`/`"large"`, default `"medium"`) is a
  convenience this library adds — MUI's own `Avatar` has no `size` prop at
  all, expecting `sx`/`className` for arbitrary sizing instead. Three
  presets covers the common case; for anything else, override `class`
  (e.g. `class="size-24"` for a big profile-page avatar — `Tails` resolves
  the conflict with the preset's own `size-*`, see `PhoenixPaper.Tails`'s
  moduledoc for why a plain `size-*` needs the same `!` treatment
  `ThemeToggle`'s icons do if you're mixing it into a `class` that also
  carries other utilities `Tails` doesn't know conflict).

  No `AvatarGroup` (MUI's overlapping-stack wrapper) — a caller gets the
  same look by rendering several `pp_avatar`s inside a flex container with
  `-space-x-*` and a `ring-2 ring-pp-surface` on each (the ring is what
  actually separates overlapping circles from each other visually; MUI's
  `AvatarGroup` adds the equivalent border itself). That's presentation
  callers can already reach with plain Tailwind, not a real gap the way
  `Snackbar`'s missing queueing is (see its moduledoc) — not worth a
  dedicated component for.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.Icon, only: [pp_icon: 1]

  attr(:src, :string, default: nil)
  attr(:alt, :string, default: "", doc: "for the <img>, when src is given")
  attr(:variant, :string, default: "circular", values: ~w(circular rounded square))
  attr(:size, :string, default: "medium", values: ~w(small medium large))
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
      data-pp-variant={@variant}
      class={Helpers.classes(@paperize, paper_classes(@variant, @size), @class)}
      {@rest}
    >
      <span :if={@inner_block != []} class="flex size-full select-none items-center justify-center leading-none">
        {render_slot(@inner_block)}
      </span>
      <.pp_icon :if={@inner_block == []} name="hero-user" class={icon_classes(@size)} />
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

  defp paper_classes(variant, size) do
    [
      "relative inline-flex shrink-0 items-center justify-center overflow-hidden bg-pp-surface-variant text-pp-on-surface",
      size_classes(size),
      variant_classes(variant)
    ]
  end

  defp size_classes("small"), do: "size-8 text-xs"
  defp size_classes("medium"), do: "size-10 text-base"
  defp size_classes("large"), do: "size-14 text-xl"

  defp variant_classes("circular"), do: "rounded-full"
  defp variant_classes("rounded"), do: "rounded-md"
  defp variant_classes("square"), do: "rounded-none"

  defp icon_classes("small"), do: "!size-4"
  defp icon_classes("medium"), do: "!size-5"
  defp icon_classes("large"), do: "!size-7"
end
