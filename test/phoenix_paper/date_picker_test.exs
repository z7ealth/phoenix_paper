defmodule PhoenixPaper.DatePickerTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  alias PhoenixPaper.DatePicker

  @endpoint PhoenixPaper.TestEndpoint

  defmodule Host do
    use Phoenix.LiveView

    def mount(_params, %{"opts" => opts, "test" => test}, socket) do
      {:ok,
       assign(socket,
         opts: :erlang.binary_to_term(opts),
         test: :erlang.binary_to_term(test),
         form: to_form(%{"due" => "2026-10-15"}, as: :task)
       )}
    end

    def render(assigns) do
      ~H"""
      <.form for={@form} id="task-form" phx-change="validate">
        <.live_component module={DatePicker} id="due" field={@form[:due]} label="Due" {@opts} />
      </.form>
      """
    end

    def handle_event("validate", params, socket) do
      send(socket.assigns.test, {:validate, params})
      {:noreply, socket}
    end

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

  test "renders the field with the ISO value and a hidden input carrying it" do
    {_view, html} = mount_picker()

    assert html =~ ~s(value="2026-10-15")
    assert html =~ ~s(name="task[due]")
    assert html =~ "hero-calendar"
    refute html =~ ~s(role="grid")
  end

  test "docked: opening shows the month grid, picking a day commits and closes" do
    {view, _} = mount_picker()

    html = view |> element("#due-field") |> render_click()
    assert html =~ ~s(role="grid")
    assert html =~ "October 2026"
    assert html =~ ~r/aria-label="2026-10-15"[^>]*aria-selected="true"/

    html = view |> element("button[aria-label='2026-10-20']") |> render_click()
    refute html =~ ~s(role="grid")
    assert html =~ ~s(value="2026-10-20")
    assert_receive {:on_change, ~D[2026-10-20]}
    assert html =~ "due-changed-1"
  end

  test "month navigation and the year grid" do
    {view, _} = mount_picker()
    view |> element("#due-field") |> render_click()

    html = view |> element("button[aria-label='Next month']") |> render_click()
    assert html =~ "November 2026"

    html = view |> element("button[aria-label='Choose year']") |> render_click()
    assert html =~ ">\n          2030\n" or html =~ "2030"
    html = view |> element("button[phx-value-year='2030']") |> render_click()
    assert html =~ "November 2030"
  end

  test "min/max disable days outside the range" do
    {view, _} = mount_picker(min: ~D[2026-10-10], max: ~D[2026-10-20])
    html = view |> element("#due-field") |> render_click()

    assert html =~ ~r/aria-label="2026-10-09"[^>]*\sdisabled[=\s>]/
    refute html =~ ~r/aria-label="2026-10-12"[^>]*\sdisabled[=\s>]/
  end

  test "modal: a pending choice only commits on OK" do
    {view, _} = mount_picker(variant: "modal")
    html = view |> element("#due-field") |> render_click()

    assert html =~ ~s(aria-modal="true")
    assert html =~ "Select date"

    html = view |> element("button[aria-label='2026-10-03']") |> render_click()
    assert html =~ "3 Oct 2026"
    assert html =~ ~s(value="2026-10-15")
    refute_received {:on_change, _}

    html = view |> element("button", "OK") |> render_click()
    assert html =~ ~s(value="2026-10-03")
    assert_receive {:on_change, ~D[2026-10-03]}
  end

  test "modal input mode switches to a native date input" do
    {view, _} = mount_picker(variant: "modal")
    view |> element("#due-field") |> render_click()
    html = view |> element("button[aria-label='Switch to text input']") |> render_click()
    assert html =~ ~s(type="date")
  end

  test "weeks/2 lays out a month with leading blanks for the first weekday" do
    # October 2026 starts on a Thursday.
    [first | _] = DatePicker.weeks(~D[2026-10-01], 7)
    assert Enum.take(first, 4) == [nil, nil, nil, nil]
    assert Enum.at(first, 4) == ~D[2026-10-01]

    [monday_first | _] = DatePicker.weeks(~D[2026-10-01], 1)
    assert Enum.take(monday_first, 3) == [nil, nil, nil]
  end

  test "next_range/2 starts, ends (swapping) and restarts a range" do
    assert DatePicker.next_range(nil, ~D[2026-10-10]) == {~D[2026-10-10], nil}

    assert DatePicker.next_range({~D[2026-10-10], nil}, ~D[2026-10-14]) ==
             {~D[2026-10-10], ~D[2026-10-14]}

    assert DatePicker.next_range({~D[2026-10-10], nil}, ~D[2026-10-02]) ==
             {~D[2026-10-02], ~D[2026-10-10]}

    assert DatePicker.next_range({~D[2026-10-02], ~D[2026-10-10]}, ~D[2026-10-20]) ==
             {~D[2026-10-20], nil}
  end

  test "range (docked): two picks commit start/end inputs and band the days between" do
    {view, _} = mount_picker(range: true, name: "trip")

    view |> element("#due-field") |> render_click()
    html = view |> element("button[aria-label='2026-10-12']") |> render_click()
    assert html =~ ~s(role="grid")

    html = view |> element("button[aria-label='2026-10-08']") |> render_click()
    refute html =~ ~s(role="grid")
    assert html =~ ~s(name="trip_start" value="2026-10-08")
    assert html =~ ~s(name="trip_end" value="2026-10-12")
    assert html =~ "2026-10-08 – 2026-10-12"
    assert_receive {:on_change, {~D[2026-10-08], ~D[2026-10-12]}}

    html = view |> element("#due-field") |> render_click()
    assert html =~ ~r/aria-label="2026-10-10"[^>]*aria-selected="true"/
    assert html =~ "bg-pp-secondary-container"
  end

  test "range (modal): headline shows the pending range, OK after one pick is a one-day range" do
    {view, _} = mount_picker(range: true, variant: "modal", name: "trip")

    html = view |> element("#due-field") |> render_click()
    assert html =~ "Select dates"

    html = view |> element("button[aria-label='2026-10-05']") |> render_click()
    assert html =~ "Oct 5 – …"

    html = view |> element("button", "OK") |> render_click()
    assert html =~ ~s(name="trip_end" value="2026-10-05")
  end
end
