defmodule Backdoor.CodeRunner do
  use GenServer

  # Public API

  def execute(runner, code) do
    GenServer.call(runner, {:execute, code})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  # Callbacks

  @impl true
  def init(_) do
    {:ok, %{bindings: [], env: init_env()}}
  end

  @impl true
  def handle_call({:execute, code}, _from, state) do
    try do
      {result, bindings, env} = do_execute(code, state.bindings, state.env)
      {:reply, {:ok, result}, %{state | bindings: bindings, env: env}}
    catch
      kind, error ->
        {:reply, {:error, kind, error, __STACKTRACE__}, state}
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
