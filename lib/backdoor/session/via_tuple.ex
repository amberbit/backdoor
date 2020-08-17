defmodule Backdoor.Session.ViaTuple do
  def via_tuple(module, session_id) do
    {:via, Registry, {Backdoor.Session.Registry, {module, session_id}}}
  end
end
