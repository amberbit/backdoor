defmodule Backdoor.Session.Log do
  use Agent

  @max_len 1000

  # Public API

  def start_link(name: name) do
    Agent.start_link(fn -> [] end, name: name)
  end

  def get_logs(agent) do
    Agent.get(agent, & &1)
  end

  def put_log(agent, log) do
    Agent.update(agent, fn list ->
      if length(list) < @max_len do
        [log | list]
      else
        {_, list} = List.pop_at(list, 0)
        [log | list]
      end
    end)
  end
end
