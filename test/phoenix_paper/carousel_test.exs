defmodule PhoenixPaper.CarouselTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Carousel

  test "multi_browse (default): snapping track, masked 28dp items, labels and links" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_carousel id="c" label="Places" controls>
        <:item label="Lake" navigate="/lake"><img src="/lake.jpg" alt="" /></:item>
        <:item><img src="/hill.jpg" alt="" /></:item>
      </.pp_carousel>
      """)

    assert html =~ ~s(aria-roledescription="carousel")
    assert html =~ "snap-x snap-mandatory"
    assert html =~ "pp-carousel-mask"
    assert html =~ "rounded-pp-xl"
    assert html =~ "w-56 h-56" or html =~ "w-56"
    assert html =~ ~s(href="/lake")
    assert html =~ "Lake"
    assert html =~ ~s(aria-label="Previous")
    assert html =~ "scrollBy"
  end

  test "layouts" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_carousel layout="hero"><:item>a</:item></.pp_carousel>
      <.pp_carousel layout="uncontained" item_size="lg"><:item>b</:item></.pp_carousel>
      <.pp_carousel layout="full_screen"><:item>c</:item></.pp_carousel>
      """)

    assert html =~ "w-[calc(100%-4rem)] snap-center"
    assert html =~ "w-72"
    assert html =~ "snap-y"
  end
end
