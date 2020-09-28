defmodule Backdoor.Session.CaptureOutput do
  use GenServer
  import Backdoor.Session.LogHelpers

  # Public API

  def start_link([session_id, name: name]) do
    GenServer.start_link(__MODULE__, session_id, name: name)
  end

  # Callbacks

  @impl true
  def init(session_id) do
    {:ok, buffer} = StringIO.open("")
    {:ok, %{session_id: session_id, buffer: buffer}}
  end

  @impl true
  def handle_info(msg, state) do
    case msg do
      {:io_request, from, reply, {:put_chars, chars}} ->
        put_chars(from, reply, chars, state)

      {:io_request, from, reply, {:put_chars, m, f, as}} ->
        put_chars(from, reply, apply(m, f, as), state)

      {:io_request, from, reply, {:put_chars, _encoding, chars}} ->
        put_chars(from, reply, chars, state)

      {:io_request, from, reply, {:put_chars, _encoding, m, f, as}} ->
        put_chars(from, reply, apply(m, f, as), state)

      {:io_request, _from, _reply, _request} = msg ->
        send(Process.group_leader(), msg)
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  defp put_chars(from, reply, chars, %{buffer: buffer} = state) do
    send(Process.group_leader(), {:io_request, from, reply, {:put_chars, chars}})

    StringIO.flush(buffer)
    send(buffer, {:io_request, from, reply, {:put_chars, chars}})
    {_, out} = StringIO.contents(buffer)

    log(state.session_id, {:output, out})

    {:noreply, state}
  end
end
