defmodule PhoenixPaper.Carousel do
  @moduledoc """
  An M3 Expressive carousel (`pp_carousel/1`) — a horizontally scrolling
  row of visual items (photos, product cards) with snap points.

      <.pp_carousel id="featured" label="Featured places">
        <:item :for={place <- @places} label={place.name} navigate={~p"/places/\#{place.id}"}>
          <img src={place.photo} alt="" class="size-full object-cover" />
        </:item>
      </.pp_carousel>

  ## Layouts

  | `layout` | behavior |
  |----------|----------|
  | `multi_browse` (default) | items of `item_size` width; items entering/leaving the edges are masked narrow and open up as they scroll in (Expressive) |
  | `hero` | one large item filling the width minus a peek of the next, snapping to center, with the same masking |
  | `uncontained` | fixed-size items, no masking, snapping to start |
  | `full_screen` | one item per screen, vertical, for immersive media |

  Items are 28dp-corner surfaces (`surface-container-highest` behind the
  content) `height` tall (`sm`/`md`/`lg`, default `md`; full-screen
  fills its container). An item's `label` is drawn over its bottom edge
  on a scrim gradient. Items with `href`/`navigate`/`patch` are links with
  a state layer and focus ring; `on_click` makes a button.

  `controls` adds previous/next icon buttons (desktop users without a
  trackpad can't swipe) — a vanilla inline `scrollBy`, no hook.

  ## How the masking works

  CSS: each item runs a `view()` scroll timeline animation of its
  `clip-path` (see `phoenix_paper.css`). Without scroll timelines
  (Firefox today) items aren't masked; with the optional JS hook and an
  `id`, the hook applies the same clip from a scroll listener.
  """
  use Phoenix.Component

  alias PhoenixPaper.Helpers
  import PhoenixPaper.IconButton, only: [pp_icon_button: 1]

  attr(:id, :string, default: nil)
  attr(:label, :string, default: nil, doc: "aria-label of the carousel region")

  attr(:layout, :string,
    default: "multi_browse",
    values: ~w(multi_browse hero uncontained full_screen)
  )

  attr(:item_size, :string,
    default: "md",
    values: ~w(sm md lg),
    doc: "item width (multi_browse, uncontained)"
  )

  attr(:height, :string, default: "md", values: ~w(sm md lg))
  attr(:controls, :boolean, default: false)
  attr(:paperize, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item, required: true do
    attr(:label, :string)
    attr(:href, :any)
    attr(:navigate, :any)
    attr(:patch, :any)
    attr(:on_click, :any)
  end

  @scroll_js "var t=this.closest('[data-pp-component=carousel]').querySelector('[data-pp-carousel-track]');var i=t.firstElementChild;t.scrollBy({left:(i?i.getBoundingClientRect().width+8:t.clientWidth*0.8)*DIR*(getComputedStyle(t).direction==='rtl'?-1:1),behavior:'smooth'});"

  @doc "Renders a carousel. See the module doc."
  def pp_carousel(assigns) do
    assigns =
      assigns
      |> assign(:prev_js, String.replace(@scroll_js, "DIR", "-1"))
      |> assign(:next_js, String.replace(@scroll_js, "DIR", "1"))

    ~H"""
    <section
      id={@id}
      aria-roledescription="carousel"
      aria-label={@label}
      data-pp-component="carousel"
      data-pp-layout={@layout}
      phx-hook={Helpers.hook(@id)}
      class={["relative", @class]}
      {@rest}
    >
      <div
        data-pp-carousel-track
        class={Helpers.classes(@paperize, track_classes(@layout), nil)}
      >
        <.carousel_item
          :for={item <- @item}
          item={item}
          layout={@layout}
          item_size={@item_size}
          height={@height}
          paperize={@paperize}
        />
      </div>
      <div :if={@controls && @layout != "full_screen"} class="mt-2 flex justify-end gap-1 px-4">
        <.pp_icon_button icon="hero-chevron-left" label="Previous" variant="tonal" ripple={false} onclick={@prev_js} />
        <.pp_icon_button icon="hero-chevron-right" label="Next" variant="tonal" ripple={false} onclick={@next_js} />
      </div>
    </section>
    """
  end

  attr(:item, :any, required: true)
  attr(:layout, :string, required: true)
  attr(:item_size, :string, required: true)
  attr(:height, :string, required: true)
  attr(:paperize, :boolean, required: true)

  defp carousel_item(assigns) do
    linked? =
      assigns.item[:href] not in [nil, false] or assigns.item[:navigate] not in [nil, false] or
        assigns.item[:patch] not in [nil, false]

    assigns = assign(assigns, :linked?, linked?)

    ~H"""
    <.link
      :if={@linked?}
      href={@item[:href]}
      navigate={@item[:navigate]}
      patch={@item[:patch]}
      data-pp-carousel-item
      class={Helpers.classes(@paperize, [item_classes(@layout, @item_size, @height), "cursor-pointer pp-state-layer pp-focus-ring"], nil)}
    >
      {item_content(assigns)}
    </.link>
    <button
      :if={!@linked? && @item[:on_click]}
      type="button"
      phx-click={@item[:on_click]}
      data-pp-carousel-item
      class={Helpers.classes(@paperize, [item_classes(@layout, @item_size, @height), "cursor-pointer text-start pp-state-layer pp-focus-ring"], nil)}
    >
      {item_content(assigns)}
    </button>
    <div
      :if={!@linked? && !@item[:on_click]}
      role="group"
      aria-roledescription="slide"
      aria-label={@item[:label]}
      data-pp-carousel-item
      class={Helpers.classes(@paperize, item_classes(@layout, @item_size, @height), nil)}
    >
      {item_content(assigns)}
    </div>
    """
  end

  defp item_content(assigns) do
    ~H"""
    {render_slot(@item)}
    <span
      :if={@item[:label]}
      class={Helpers.classes(@paperize, "pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-pp-scrim/60 to-transparent px-4 pt-8 pb-4 pp-title-medium text-white", nil)}
    >
      {@item.label}
    </span>
    """
  end

  defp track_classes("full_screen"),
    do: "flex h-full snap-y snap-mandatory flex-col gap-2 overflow-y-auto [scrollbar-width:none]"

  defp track_classes("hero"),
    do: "flex snap-x snap-mandatory gap-2 overflow-x-auto scroll-px-4 px-4 [scrollbar-width:none]"

  defp track_classes(_layout),
    do: "flex snap-x snap-mandatory gap-2 overflow-x-auto scroll-px-4 px-4 [scrollbar-width:none]"

  defp item_classes(layout, size, height) do
    [
      "relative block shrink-0 overflow-hidden rounded-pp-xl bg-pp-surface-container-highest",
      layout_classes(layout, size),
      height_classes(layout, height)
    ]
  end

  defp layout_classes("multi_browse", size), do: ["snap-start pp-carousel-mask", width(size)]
  defp layout_classes("uncontained", size), do: ["snap-start", width(size)]
  defp layout_classes("hero", _size), do: "w-[calc(100%-4rem)] snap-center pp-carousel-mask"
  defp layout_classes("full_screen", _size), do: "w-full snap-start"

  defp width("sm"), do: "w-40"
  defp width("md"), do: "w-56"
  defp width("lg"), do: "w-72"

  defp height_classes("full_screen", _height), do: "h-full"
  defp height_classes(_layout, "sm"), do: "h-40"
  defp height_classes(_layout, "md"), do: "h-56"
  defp height_classes(_layout, "lg"), do: "h-80"
end
