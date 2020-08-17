defmodule Backdoor.Session.Counter do
  use Agent

  # Public API

  def start_link(name: name) do
    Agent.start_link(fn -> 0 end, name: name)
  end

  def next_id(agent \\ __MODULE__) do
    Agent.get_and_update(agent, &{&1 + 1, &1 + 1})
  end
end
