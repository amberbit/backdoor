defmodule Backdoor.Session.CodeRunner do
  use GenServer
  import Backdoor.Session.LogHelpers
  import Backdoor.Session.ViaTuple
  require Logger

  # Public API

  def start_link([session_id, name: name]) do
    GenServer.start_link(__MODULE__, session_id, name: name)
  end

  # Callbacks

  @impl true
  def init(session_id) do
    Logger.metadata(backdoor_session_id: session_id)
    {:ok, %{session_id: session_id, bindings: [], env: init_env()}}
  end

  @impl true
  def handle_info({:io_reply, _, :ok}, state) do
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("[#{__MODULE__} received unexpected message which was ignored:\n#{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:execute, code}, _from, state) do
    pid = GenServer.whereis(via_tuple(Backdoor.Session.CaptureOutput, state.session_id))
    Process.group_leader(self(), pid)

    try do
      log(state.session_id, {:input, code})
      {result, bindings, env} = do_execute(code, state.bindings, state.env)
      log(state.session_id, {:result, result})
      {:reply, [{:input, code}, {:result, result}], %{state | bindings: bindings, env: env}}
    catch
      kind, error ->
        log(state.session_id, {:error, kind, error, __STACKTRACE__})
        {:reply, [{:input, code}, {:error, kind, error, __STACKTRACE__}], state}
    end
  end

  # private

  defp do_execute(code, bindings, env) do
    {:ok, ast} = Code.string_to_quoted(code)
    :elixir.eval_forms(ast, bindings, env)
  end

  defp init_env do
    :elixir.env_for_eval(file: "backdoor")
  end
end
