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
      <.pp_text_field name="ends_at" type="datetime-local" label="Ends" value={~U[2026-10-01 18:05:00Z]} />
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
    # The notch is no longer shifted for a start adornment: the raised
    # outlined label moves to the box edge instead (MD3), where the notch is.
    refute html =~ "ms-12"
  end

  test "paperize={false} renders no built-in classes and no fieldset" do
    assigns = %{}

    html =
      rendered_to_string(~H"<.pp_text_field name='q' label='Q' paperize={false} class='mine' />")

    refute html =~ "pp-body-large"
    refute html =~ "<fieldset"
    assert html =~ "mine"
  end

  describe ":chips" do
    defp chip_field(assigns) do
      ~H"""
      <.pp_text_field id="to" name="to" label="To" variant={@variant}>
        <:chips><span data-chip>Ana</span><span data-chip>Bo</span></:chips>
      </.pp_text_field>
      """
    end

    test "chips render inside the field box, before the input, in a wrapping row" do
      html = render_component(&chip_field/1, variant: "outlined")

      assert html =~
               ~r/flex-wrap items-center gap-2 px-4 py-3[^>]*>\s*<span data-chip>Ana<\/span><span data-chip>Bo<\/span>\s*<input/

      [input] = Regex.run(~r/<input[^>]*id="to"[^>]*>/, html)
      assert input =~ "min-w-[4ch] flex-1"
      assert html =~ "this.querySelector(&#39;input&#39;).focus()"
    end

    test "the label stays raised and the outlined notch open, whatever :placeholder-shown says" do
      html = render_component(&chip_field/1, variant: "outlined")

      [label] = Regex.run(~r/<label[^>]*for="to"[^>]*>/, html)
      assert label =~ "top-0 -translate-y-1/2 pp-body-small"
      refute label =~ "top-1/2"
      refute label =~ "peer-[:not(:placeholder-shown)]"
      assert html =~ "[&amp;&gt;fieldset&gt;legend]:max-w-full [&amp;&gt;fieldset&gt;legend]:px-1"
    end

    test "filled: the label is raised to the top of the box, the row leaves room for it" do
      html = render_component(&chip_field/1, variant: "filled")

      [label] = Regex.run(~r/<label[^>]*for="to"[^>]*>/, html)
      assert label =~ "top-2 translate-y-0 pp-body-small"
      assert html =~ "px-4 pt-6 pb-2"
    end

    test "without chips nothing changes; multiline ignores the slot" do
      assigns = %{}

      plain = rendered_to_string(~H"<.pp_text_field name='q' label='Q' />")
      [label] = Regex.run(~r/<label[^>]*>/, plain)
      assert label =~ "top-1/2"
      refute plain =~ "min-w-[4ch]"
      refute plain =~ ~r/>\s*false\s*</

      multi =
        rendered_to_string(~H"""
        <.pp_text_field name="b" label="B" multiline><:chips><span data-chip>x</span></:chips></.pp_text_field>
        """)

      refute multi =~ "data-chip"
    end
  end

  test ":menu renders inside the field box, its positioning ancestor" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.pp_text_field name="q" label="Q"><:menu><div data-menu class="absolute top-full">m</div></:menu></.pp_text_field>
      """)

    assert html =~ ~r/<\/fieldset>\s*<div data-menu/
  end

  describe "outlined geometry" do
    test "the fieldset starts 8px above the box, so its border (drawn through the legend's middle) is on the box edge" do
      assigns = %{}
      html = rendered_to_string(~H"<.pp_text_field name='q' label='Q' />")

      [fieldset] = Regex.run(~r/<fieldset[^>]*>/, html)
      assert fieldset =~ "inset-x-0 bottom-0 -top-2"
      refute fieldset =~ "inset-0"
    end

    test "the label's containing block is the field box; raised outlined labels go to its edge, filled ones stay with the text" do
      assigns = %{}

      outlined =
        rendered_to_string(~H"""
        <.pp_text_field id="o" name="o" label="Amount"><:start_adornment>$</:start_adornment></.pp_text_field>
        """)

      refute outlined =~ ~s(class="relative min-w-0 flex-1")
      [label] = Regex.run(~r/<label[^>]*for="o"[^>]*>/, outlined)
      assert label =~ " ms-4 "
      refute label =~ " start-4 "
      assert label =~ "peer-focus:start-0"
      assert label =~ "peer-[:not(:placeholder-shown)]:start-0"

      filled =
        rendered_to_string(~H"""
        <.pp_text_field id="f" name="f" label="Amount" variant="filled"><:start_adornment>$</:start_adornment></.pp_text_field>
        """)

      [label] = Regex.run(~r/<label[^>]*for="f"[^>]*>/, filled)
      refute label =~ "start-0"
    end
  end
end
