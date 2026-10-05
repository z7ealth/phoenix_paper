defmodule PhoenixPaper.TextFieldTest do
  use ExUnit.Case, async: true

  use Phoenix.Component
  import Phoenix.LiveViewTest
  import PhoenixPaper.TextField

  test "field= populates name/id/value from the form field" do
    form = Phoenix.Component.to_form(%{"email" => "hello@example.com"}, as: :user)
    assigns = %{form: form}

    html = rendered_to_string(~H"<.pp_text_field field={@form[:email]} label='Email' />")

    assert html =~ ~s(id="user_email")
    assert html =~ ~s(name="user[email]")
    assert html =~ ~s(value="hello@example.com")
  end

  test "datetime-local formats a NaiveDateTime/DateTime value the way the input requires" do
    form = Phoenix.Component.to_form(%{"starts_at" => ~N[2026-10-01 09:30:15]}, as: :event)
    assigns = %{form: form}

    html =
      rendered_to_string(~H"""
      <.pp_text_field field={@form[:starts_at]} type="datetime-local" label="Starts" />
      <.pp_text_field name="ends_at" type="datetime-local" label="Ends" value={~U[2026-10-01 18:05:00Z]} hide_label />
      """)

    assert html =~ ~s(value="2026-10-01T09:30")
    assert html =~ ~s(value="2026-10-01T18:05")
    refute html =~ "09:30:15"
  end

  test "outlined (default): MD3 outline, floating label on the border, notch fieldset" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_text_field name='email' label='Email' />")

    assert html =~ ~s(data-pp-component="text-field")
    assert html =~ "border-pp-outline"
    assert html =~ "min-h-14"
    assert html =~ "pp-body-large"
    assert html =~ "peer-focus:-translate-y-1/2"
    assert html =~ "peer-focus:pp-body-small"
    assert html =~ "<fieldset"
    assert html =~ ~s(placeholder=" ")
  end

  test "the closed legend has no resting padding, and opens on focus/content scoped to the input tag" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_text_field name='email' label='Email' />")

    assert html =~ "max-w-0"
    assert html =~ "px-0"
    assert html =~ "has-[input:not(:placeholder-shown)]:[&amp;&gt;fieldset&gt;legend]:max-w-full"
    assert html =~ "focus-within:[&amp;&gt;fieldset&gt;legend]:px-1"
    refute html =~ "has-[:not(:placeholder-shown)]"
  end

  test "filled: surface-container-highest, top corners, inset-shadow active indicator, no notch" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_text_field name='q' label='Q' variant='filled' />")

    assert html =~ "bg-pp-surface-container-highest"
    assert html =~ "rounded-t-pp-xs"
    assert html =~ "shadow-[inset_0_-1px_0_0_var(--color-pp-on-surface-variant)]"
    assert html =~ "focus-within:shadow-[inset_0_-2px_0_0_var(--color-pp-primary)]"
    refute html =~ "<fieldset"
  end

  test "color picks the focus color; tertiary replaces 0.3's accent" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_text_field name='a' label='A' color='tertiary' />")

    assert html =~ "focus-within:[&amp;&gt;fieldset]:!border-pp-tertiary"
    assert html =~ "peer-focus:text-pp-tertiary"
  end

  test "errors replace supporting text, color the label and add a trailing error icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_text_field id="e" name="e" label="E" supporting_text="Hint" errors={["is invalid"]} />
      """)

    assert html =~ "is invalid"
    refute html =~ "Hint"
    assert html =~ "text-pp-error"
    assert html =~ "hero-exclamation-circle"
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(aria-describedby="e-supporting")
  end

  test "supporting_text renders under the field" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_text_field id='s' name='s' label='S' supporting_text='Hint' />")

    assert html =~ "Hint"
    assert html =~ "pp-body-small"
  end

  test "multiline renders a textarea with rows and the value, label on the first line" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_text_field name='bio' label='Bio' multiline rows={4} value='hi' />"
      )

    assert html =~ ~s(<textarea)
    assert html =~ ~s(rows="4")
    assert html =~ ">hi</textarea>"
    assert html =~ "top-4"
  end

  test "adornments render as flex siblings of the input" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_text_field name="amount" label="Amount">
        <:start_adornment>$</:start_adornment>
        <:end_adornment>USD</:end_adornment>
      </.pp_text_field>
      """)

    assert html =~ ~s(data-pp-adornment="start")
    assert html =~ ~s(data-pp-adornment="end")
    assert html =~ "has-[[data-pp-adornment=start]]:[&amp;&gt;fieldset&gt;legend]:ms-12"
  end

  test "hide_label: no label/fieldset/supporting text, label becomes the placeholder" do
    assigns = %{}

    html =
      rendered_to_string(
        ~H"<.pp_text_field name='q' label='Search' hide_label size='small' supporting_text='x' />"
      )

    assert html =~ ~s(placeholder="Search")
    assert html =~ ~s(data-pp-dense="true")
    refute html =~ "<label"
    refute html =~ "<fieldset"
    refute html =~ ">x<"
  end

  test "paperize={false} renders no built-in classes and no fieldset" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_text_field name='q' label='Q' paperize={false} class='mine' />")

    refute html =~ "pp-body-large"
    refute html =~ "<fieldset"
    assert html =~ "mine"
  end

  test "small size is the dense 40dp field" do
    assigns = %{}
    html = rendered_to_string(~H"<.pp_text_field name='q' label='Q' size='small' />")

    assert html =~ "min-h-10"
    assert html =~ "pp-body-medium"
  end
end
