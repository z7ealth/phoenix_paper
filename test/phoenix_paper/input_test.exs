defmodule PhoenixPaper.InputTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.Input

  test "field= populates name/id/value from the form field" do
    html = render_component(&with_field/1)

    assert html =~ ~s(id="user_email")
    assert html =~ ~s(name="user[email]")
    assert html =~ ~s(value="hello@example.com")
  end

  defp with_field(assigns) do
    form = Phoenix.Component.to_form(%{"email" => "hello@example.com"}, as: :user)

    assigns = assign(assigns, :form, form)

    ~H"""
    <.pp_input field={@form[:email]} label="Email" />
    """
  end

  test "renders the floating label and outlined classes by default" do
    html = render_component(&outlined/1)

    assert html =~ "border-pp-outline"
    assert html =~ "peer-focus:text-xs"
    assert html =~ "Email"
    assert html =~ ~s(placeholder=" ")
  end

  defp outlined(assigns) do
    ~H"""
    <.pp_input label="Email" name="email" />
    """
  end

  test "filled variant only rounds the top corners" do
    html = render_component(&filled/1)
    assert html =~ ~r/\brounded-t\b/
    assert html =~ "bg-pp-surface-variant"
  end

  defp filled(assigns) do
    ~H"""
    <.pp_input variant="filled" label="Name" name="name" />
    """
  end

  test "renders error messages and error classes instead of helper text" do
    html = render_component(&with_errors/1)

    assert html =~ "border-pp-error"
    assert html =~ "can&#39;t be blank"
    refute html =~ "Must be at least 3 characters"
  end

  defp with_errors(assigns) do
    ~H"""
    <.pp_input label="Name" name="name" errors={["can't be blank"]} helper_text="Must be at least 3 characters" />
    """
  end

  test "paperize={false} renders a bare input with no built-in classes" do
    html = render_component(&bare/1)

    refute html =~ "border-pp-outline"
    refute html =~ "peer-focus"
    assert html =~ "my-input"
  end

  defp bare(assigns) do
    ~H"""
    <.pp_input paperize={false} label="Email" name="email" class="my-input" />
    """
  end

  test "variant=\"standard\" is underline-only, no shape/background" do
    html = render_component(&standard/1)

    assert html =~ "border-b"
    refute html =~ "bg-pp-surface-variant"
    refute html =~ "rounded"
  end

  defp standard(assigns) do
    ~H"""
    <.pp_input variant="standard" label="Name" name="name" />
    """
  end

  test "color picks the focus/label color, ignored when there are errors" do
    html = render_component(&secondary/1)
    assert html =~ "border-pp-secondary"
    assert html =~ "peer-focus:text-pp-secondary"

    html = render_component(&secondary_with_error/1)
    refute html =~ "pp-secondary"
    assert html =~ "border-pp-error"
  end

  defp secondary(assigns) do
    ~H"""
    <.pp_input color="secondary" label="Name" name="name" />
    """
  end

  defp secondary_with_error(assigns) do
    ~H"""
    <.pp_input color="secondary" label="Name" name="name" errors={["is required"]} />
    """
  end

  test "size=\"small\" uses tighter vertical padding" do
    html = render_component(&small/1)
    assert html =~ "pt-5"
    assert html =~ "pb-1.5"
  end

  defp small(assigns) do
    ~H"""
    <.pp_input size="small" label="Name" name="name" />
    """
  end

  test "multiline renders a textarea instead of an input, with rows and the same value" do
    html = render_component(&multiline/1)

    assert html =~ "<textarea"
    refute html =~ "<input"
    assert html =~ ~s(rows="4")
    assert html =~ "Hello there"
  end

  defp multiline(assigns) do
    ~H"""
    <.pp_input multiline rows={4} label="Bio" name="bio" value="Hello there" />
    """
  end

  test "start_adornment and end_adornment render as flex siblings around the input" do
    html = render_component(&with_adornments/1)

    assert html =~ "$"
    assert html =~ "USD"
  end

  defp with_adornments(assigns) do
    ~H"""
    <.pp_input label="Amount" name="amount">
      <:start_adornment>$</:start_adornment>
      <:end_adornment>USD</:end_adornment>
    </.pp_input>
    """
  end

  test "outlined renders a real fieldset/legend notch containing the label text, closed by default" do
    html = render_component(&outlined/1)

    assert html =~ "<fieldset"
    assert html =~ "<legend"
    assert html =~ ~r/<legend[^>]*class="[^"]*max-w-0[^"]*"/
    assert html =~ "Email"
  end

  test "the closed legend has no resting padding — max-width alone can't shrink an element below its own padding" do
    html = render_component(&outlined/1)
    assert html =~ ~r/<legend[^>]*class="[^"]*\bpx-0\b[^"]*"/
    refute html =~ ~r/<legend[^>]*class="[^"]*\bpx-1\b[^"]*"/
  end

  test "the notch opens on focus or once the input has content, scoped to the actual input tag" do
    html = render_component(&outlined/1)

    assert html =~ "has-[input:not(:placeholder-shown)]:"
    assert html =~ "has-[textarea:not(:placeholder-shown)]:"
    assert html =~ "focus-within:"
    assert html =~ "fieldset&gt;legend]:max-w-full"
    refute html =~ "has-[:not(:placeholder-shown)]:"
  end

  test "filled/standard don't render a notch fieldset" do
    refute render_component(&filled/1) =~ "<fieldset"
    refute render_component(&standard/1) =~ "<fieldset"
  end

  test "paperize={false} renders no fieldset at all" do
    refute render_component(&bare/1) =~ "<fieldset"
  end
end
