defmodule Backdoor.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    children = [
      {Backdoor.Session.Counter, name: Backdoor.Session.Counter},
      {DynamicSupervisor, name: Backdoor.Session.DynamicSupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: Backdoor.Session.Registry}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
