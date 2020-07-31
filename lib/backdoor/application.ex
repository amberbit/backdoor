defmodule Backdoor.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    children = [
      {Backdoor.CodeRunner, name: Backdoor.CodeRunner},
      {DynamicSupervisor, name: Backdoor.DynamicSupervisor, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
