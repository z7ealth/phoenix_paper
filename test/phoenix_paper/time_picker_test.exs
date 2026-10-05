defmodule PhoenixPaper.TimePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  alias PhoenixPaper.TimePicker

  @endpoint PhoenixPaper.TestEndpoint

  defmodule Host do
    use Phoenix.LiveView

    def mount(_params, %{"opts" => opts, "test" => test}, socket) do
      {:ok,
       assign(socket,
         opts: :erlang.binary_to_term(opts),
         test: :erlang.binary_to_term(test),
         form: to_form(%{"at" => "14:05"}, as: :event)
       )}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="event-form" phx-change="validate">
        <.live_component module={TimePicker} id="at" field={@form[:at]} label="Starts" {@opts} />
      </.form>
      """
    end

    def handle_event("validate", _params, socket), do: {:noreply, socket}

    def handle_info({:changed, value}, socket) do
      send(socket.assigns.test, {:on_change, value})
      {:noreply, socket}
    end
  end

  defp mount_picker(opts \\ []) do
    test = self()
    opts = Keyword.put_new(opts, :on_change, fn value -> send(self(), {:changed, value}) end)

    {:ok, view, html} =
      live_isolated(build_conn(), Host,
        session: %{
          "opts" => :erlang.term_to_binary(Map.new(opts)),
          "test" => :erlang.term_to_binary(test)
        }
      )

    {view, html}
  end

  defp build_conn, do: Phoenix.ConnTest.build_conn()

  test "renders the 12h display and the 24h hidden value" do
    {_view, html} = mount_picker()
    assert html =~ ~s(value="2:05 PM")
    assert html =~ ~s(value="14:05")
    assert html =~ ~s(name="event[at]")
  end

  test "dial: pick an hour (moves to minutes), a minute, AM; OK commits" do
    {view, _} = mount_picker()

    html = view |> element("#at-field") |> render_click()
    assert html =~ "Select time"
    assert html =~ ~s(aria-label="Hour")
    assert html =~ ~r/aria-label="2"[^>]*aria-pressed="true"/

    html = view |> element("button[phx-value-hour='9']") |> render_click()
    assert html =~ ~r/aria-label="Minute"[^>]*aria-pressed="true"/

    view |> element("button[phx-value-minute='30']") |> render_click()
    view |> element("button[phx-value-period='am']") |> render_click()
    refute_received {:on_change, _}

    html = view |> element("button", "OK") |> render_click()
    assert html =~ ~s(value="09:30")
    assert_receive {:on_change, ~T[09:30:00]}
  end

  test "24h dial puts 13–00 on an inner ring and has no AM/PM" do
    {view, _} = mount_picker(hour_cycle: 24)
    html = view |> element("#at-field") |> render_click()

    assert html =~ ~s(aria-label="13")
    assert html =~ ~s(aria-label="00")
    refute html =~ "AM or PM"
  end

  test "input mode renders numeric fields" do
    {view, _} = mount_picker()
    view |> element("#at-field") |> render_click()
    html = view |> element("button[aria-label='Switch to text input']") |> render_click()
    assert html =~ ~s(type="number")
    assert html =~ "Enter time"
  end

  test "dial_numbers places 12 at the top" do
    [{12, "12", x, y} | _] =
      Enum.filter(TimePicker.dial_numbers(:hour, 12), &match?({12, _, _, _}, &1))

    assert x == 104.0
    assert y == 4.0
  end

  test "dial events from the hook: drag to an hour, release moves on, exact minutes" do
    {view, _} = mount_picker()
    html = view |> element("#at-field") |> render_click()
    assert html =~ ~s(id="at-dial")
    assert html =~ ~s(data-pp-selecting="hour")

    html = view |> with_target("#at") |> render_hook("dial", %{"part" => "hour", "value" => 4})
    assert html =~ ~s(data-pp-selecting="hour")

    html =
      view
      |> with_target("#at")
      |> render_hook("dial", %{"part" => "hour", "value" => 4, "done" => true})

    assert html =~ ~s(data-pp-selecting="minute")

    view |> with_target("#at") |> render_hook("dial", %{"part" => "minute", "value" => 37})
    html = view |> element("button", "OK") |> render_click()
    assert html =~ ~s(value="16:37")
  end
end
