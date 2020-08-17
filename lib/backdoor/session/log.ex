defmodule Backdoor.Session.Log do
  use Agent

  # Public API

  def start_link(name: name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  def get_logs(agent) do
    Agent.get(agent, & &1)
  end

  def put_log(agent, log) do
    Agent.update(agent, &(&1 ++ [log]))
  end
end
