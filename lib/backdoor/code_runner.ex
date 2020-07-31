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
    {:ok, ast} = Code.string_to_quoted(code)
    {result, bindings, env} = :elixir.eval_forms(ast, state.bindings, state.env)

    {:reply, result, %{state | bindings: bindings, env: env}}
  end

  # private

  defp init_env do
    :elixir.env_for_eval(file: "backdoor")
  end
end
