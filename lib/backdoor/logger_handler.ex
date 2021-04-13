defmodule Backdoor.LoggerHandler do
  def log(%{meta: %{backdoor_session_id: session_id}} = log, _config) do
    Backdoor.Session.LogHelpers.log(session_id, log)
    :ok
  end

  def log(_log, _config), do: :ok
end
