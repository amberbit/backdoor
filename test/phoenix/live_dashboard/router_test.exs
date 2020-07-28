defmodule Phoenix.LiveDashboard.RouterTest do
  use ExUnit.Case, async: true

  alias Phoenix.LiveDashboard.Router

  test "default options" do
    assert Router.__options__([]) == [
             session: {Phoenix.LiveDashboard.Router, :__session__, [nil, nil, nil]},
             private: %{live_socket_path: "/live"},
             layout: {Phoenix.LiveDashboard.LayoutView, :dash},
             as: :live_dashboard
           ]
  end

  test "configures live_socket_path" do
    assert Router.__options__(live_socket_path: "/custom/live")[:private] ==
             %{live_socket_path: "/custom/live"}
  end

  test "configures metrics" do
    assert Router.__options__(metrics: Foo)[:session] ==
             {Phoenix.LiveDashboard.Router, :__session__, [{Foo, :metrics}, nil, nil]}

    assert Router.__options__(metrics: {Foo, :bar})[:session] ==
             {Phoenix.LiveDashboard.Router, :__session__, [{Foo, :bar}, nil, nil]}

    assert_raise ArgumentError, fn ->
      Router.__options__(metrics: [])
    end
  end

  test "configures env_keys" do
    assert Router.__options__(env_keys: ["USER", "ROOTDIR"])[:session] ==
             {Phoenix.LiveDashboard.Router, :__session__, [nil, ["USER", "ROOTDIR"], nil]}

    assert_raise ArgumentError, fn ->
      Router.__options__(env_keys: "FOO")
    end
  end

  test "accepts metrics_history option" do
    assert Router.__options__(metrics_history: {MyStorage, :metrics_history, []})[:session] ==
             {Phoenix.LiveDashboard.Router, :__session__,
              [nil, nil, {MyStorage, :metrics_history, []}]}

    assert_raise ArgumentError, fn ->
      Router.__options__(metrics_history: %{namespace: {MyStorage, :metrics_history, []}})
    end

    assert_raise ArgumentError, fn ->
      Router.__options__(metrics_history: %{[:namespace, :metric] => MyStorage})
    end
  end
end
