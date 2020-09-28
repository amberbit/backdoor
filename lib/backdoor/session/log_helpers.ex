defmodule Backdoor.Session.LogHelpers do
  import Backdoor.Session.ViaTuple

  @topic_name "backdoor_events"

  def log(session_id, value) do
    Phoenix.PubSub.broadcast(pubsub_server(), @topic_name, {:put_log, session_id, value})
    Backdoor.Session.Log.put_log(via_tuple(Backdoor.Session.Log, session_id), value)
  end

  defp pubsub_server() do
    Application.get_env(:backdoor, :pubsub_server)
  end
end
