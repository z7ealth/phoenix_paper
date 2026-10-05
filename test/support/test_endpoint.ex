defmodule PhoenixPaper.TestEndpoint do
  @moduledoc false
  # Lets `Phoenix.LiveViewTest.live_isolated/3` mount real LiveViews, for the
  # LiveComponents (DatePicker, TimePicker) whose behavior lives in event
  # handlers. It never serves HTTP: `server: false` is Phoenix's default.
  use Phoenix.Endpoint, otp_app: :phoenix_paper

  socket("/live", Phoenix.LiveView.Socket)
end
