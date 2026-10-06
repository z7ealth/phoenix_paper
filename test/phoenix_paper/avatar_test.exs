defmodule PhoenixPaper.AvatarTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Avatar

  test "with no src and no inner_block, falls back to a generic person icon" do
    html = render_component(&bare_default/1)

    assert html =~ "hero-user"
    refute html =~ "<img"
  end

  defp bare_default(assigns) do
    ~H"""
    <.pp_avatar />
    """
  end

  test "inner_block renders initials instead of the default icon" do
    html = render_component(&initials/1)

    assert html =~ "OP"
    refute html =~ "hero-user"
  end

  defp initials(assigns) do
    ~H"""
    <.pp_avatar>OP</.pp_avatar>
    """
  end

  test "src renders an <img> with a vanilla onerror fallback, alongside the initials fallback" do
    html = render_component(&with_src/1)

    assert html =~ "<img"
    assert html =~ ~s(src="/images/1.jpg")
    assert html =~ ~s(alt="Remy Sharp")
    assert html =~ "this.style.display='none'"
    assert html =~ "OP"
  end

  defp with_src(assigns) do
    ~H"""
    <.pp_avatar src="/images/1.jpg" alt="Remy Sharp">OP</.pp_avatar>
    """
  end

  test "MD3's avatar: a 40dp primary-container circle with title-medium initials" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_avatar>AB</.pp_avatar>")

    assert html =~ "size-10"
    assert html =~ "rounded-pp-full"
    assert html =~ "bg-pp-primary-container"
    assert html =~ "text-pp-on-primary-container"
    assert html =~ "pp-title-medium"
  end

  test "paperize={false}: no built-in classes, only the caller's" do
    html = render_component(&bare/1)

    refute html =~ "bg-pp-primary-container"
    refute html =~ "size-10"
    assert html =~ "my-class"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_avatar paperize={false} class="my-class" />
    """
  end
end
