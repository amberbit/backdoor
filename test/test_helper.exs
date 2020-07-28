Application.put_env(:backdoor, BackdoorTest.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  render_errors: [view: BackdoorTest.ErrorView],
  check_origin: false,
  pubsub_server: BackdoorTest.PubSub
)

defmodule BackdoorTest.ErrorView do
  use Phoenix.View, root: "test/templates"

  def template_not_found(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule BackdoorTest.Router do
  use Phoenix.Router
  import Backdoor.Router

  pipeline :browser do
    plug :fetch_session
  end

  scope "/", ThisWontBeUsed, as: :this_wont_be_used do
    pipe_through :browser

    backdoor("/backdoor")
  end
end

defmodule BackdoorTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :backdoor

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"

  plug BackdoorTest.Router
end

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: BackdoorTest.PubSub, adapter: Phoenix.PubSub.PG2},
    BackdoorTest.Endpoint
  ],
  strategy: :one_for_one
)

ExUnit.start()
