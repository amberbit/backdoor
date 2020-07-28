# Backdoor

## Installation

To start using Backdoor, you will need three steps:

  1. Add the `backdoor` dependency
  2. Configure LiveView
  3. Add backdoor access

### 1. Add the `backdoor` dependency

Add the following to your `mix.exs` and run `mix deps.get`:

```elixir
def deps do
  [
    {:backdoor, "~> 0.1"}
  ]
end
```

### 2. Configure LiveView

The Backdoor is built on top of LiveView. If LiveView is already installed in your app, feel free to skip this section.

If you plan to use LiveView in your application in the future, we recommend you to follow [the official installation instructions](https://hexdocs.pm/phoenix_live_view/installation.html).
This guide only covers the minimum steps necessary for the LiveDashboard itself to run.

First, update your endpoint's configuration to include a signing salt. You can generate a signing salt by running `mix phx.gen.secret 32` (note Phoenix v1.5+ apps already have this configuration):

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  live_view: [signing_salt: "SECRET_SALT"]
```
Then add the `Phoenix.LiveView.Socket` declaration to your endpoint:

```elixir
socket "/live", Phoenix.LiveView.Socket
```

And you are good to go!

### 3. Add backdoor access for development-only usage

Once installed, update your router's configuration to forward requests to a Backdoor with a unique `name` of your choosing:

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import Backdoor.Router

...

if Mix.env() == :dev do
  scope "/" do
    pipe_through :browser
    backdoor "/web_console"
  end
end
```

This is all. Run `mix phx.server` and access the "/web_console" to configure the necessary modules.

### Extra: Add backdoor access on all environments (including production)

If you want to use the Backdoor in production, you should put it behind some authentication and allow only admins to access it. If your application does not have an admins-only section yet, you can use `Plug.BasicAuth` to set up some basic authentication as long as you are also using SSL (which you should anyway):

```elixir
# lib/my_app_web/router.ex
use MyAppWeb, :router
import Plug.BasicAuth
import Backdoor.Router

...

pipeline :admins_only do
  plug :basic_auth, username: "admin", password: "a very special secret"
end

scope "/" do
  pipe_through [:browser, :admins_only]
  backdoor "/web_console"
end
```

If you are running your application behind a proxy or a webserver, you also have to make sure they are configured for allowing WebSocket upgrades. For example, [here is an article](https://dennisreimann.de/articles/phoenix-nginx-config.html) on how to configure Nginx with Phoenix and WebSockets.

Finally, you will also want to configure your `config/prod.exs` and use your domain name under the `check_origin` configuration:

    check_origin: ["//myapp.com"]

Then you should be good to go!

<!-- MDOC !-->

## Contributing

For those planning to contribute to this project, you can run a dev version of the dashboard with the following commands:

    $ mix setup
    $ mix dev

Alternatively, run `iex -S mix dev` if you also want a shell.

## License

MIT License. Copyright (c) 2019 AmberBit Sp. z o. o.
MIT License. Copyright (c) 2019 Michael Crumm, Chris McCord, José Valim.
