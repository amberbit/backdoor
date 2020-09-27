defmodule Backdoor.Session do
  import Backdoor.Session.ViaTuple

  # Public API
  #
  def start_session() do
    with session_id <- Backdoor.Session.Counter.next_id(),
         spec <- %{
           id: :ignored,
           start: {Backdoor.Session.Supervisor, :start_link, [session_id]},
           restart: :transient,
           type: :supervisor
         },
         {:ok, _pid} <- DynamicSupervisor.start_child(Backdoor.Session.DynamicSupervisor, spec) do
      broadcast_session_ids()
      {:ok, session_id}
    end
  end

  def stop_session(session_id) do
    with [{supervisor_pid, _}] <-
           Registry.lookup(Backdoor.Session.Registry, {Backdoor.Session.Supervisor, session_id}) do
      Supervisor.stop(supervisor_pid, :normal)
      broadcast_session_ids()
      :ok
    else
      [] ->
        broadcast_session_ids()
        {:error, :not_found}

      err ->
        broadcast_session_ids()
        err
    end
  end

  def session_ids() do
    Backdoor.Session.Registry
    |> Registry.select([{{{Backdoor.Session.Supervisor, :"$1"}, :"$2", :"$3"}, [], [{{:"$1"}}]}])
    |> Enum.map(&elem(&1, 0))
    |> Enum.sort()
  end

  def execute(session_id, code) do
    GenServer.call(via_tuple(Backdoor.Session.CodeRunner, session_id), {:execute, code})
  end

  def get_logs(session_id) do
    Backdoor.Session.Log.get_logs(via_tuple(Backdoor.Session.Log, session_id))
  end

  @topic_name "backdoor_events"

  defp broadcast_session_ids() do
    Phoenix.PubSub.broadcast(pubsub_server(), @topic_name, {:session_ids, session_ids()})
  end

  defp pubsub_server() do
    Application.get_env(:backdoor, :pubsub_server)
  end
end
