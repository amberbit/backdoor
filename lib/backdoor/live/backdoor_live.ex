defmodule Backdoor.BackdoorLive do
  use Phoenix.LiveView,
    layout: {Backdoor.LayoutView, "live.html"},
    container: {:div, class: "font-sans antialiased h-screen flex"}

  use Backdoor.Web, :live_view

  @topic_name "backdoor_events"

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(find_pubsub_server(socket.endpoint), @topic_name)

    {:ok,
     socket
     |> assign(
       input_value: "",
       current_session_id: nil,
       session_ids: Backdoor.Session.session_ids(),
       logs: []
     )}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="font-sans antialiased h-screen flex w-full">
      <!-- Sidebar: -->
      <div class="flex-none w-1/6 hidden md:block p-4">
        <%= link "New session", to: "#", phx_click: :start_session, class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded" %>
        <ul class="py-4">
          <%= for session_id <- @session_ids do %>
            <li>
              <%= link to: "#", class: "float-right", phx_click: :stop_session, phx_value_session_id: session_id do %>
                [x]
              <% end %>
              <%= link "##{session_id}", to: "#", phx_click: :switch_session, phx_value_session_id: session_id %>
            </li>
          <% end %>
        </ul>
      </div>
      <!-- Main column -->
      <%= if @current_session_id do %>
        <div class="flex-1 flex flex-col overflow-hidden">
          <!-- Titlebar -->
          <div class="border-b flex px-6 py-2 items-center flex-none">
            <h3 class="text-grey-darkest mb-1 font-extrabold">Session: #<%= @current_session_id %></h3>
          </div>
          <!-- Output -->
          <div class="px-6 py-4 flex-1 overflow-y-scroll">
            <%= for log <- @logs do %>
              <div class="flex items-start text-sm">
                <pre><%= format(log) %></pre>
              </div>
            <% end %>
          </div>
          <!-- Input -->
          <div class="pb-6 px-4 flex-none">
            <div class="flex rounded-lg border-2 border-grey overflow-hidden">
              <span class="text-xl text-grey border-r-0 border-grey p-2 px-0">
                backdoor&gt;
              </span>
              <%= form_tag "#", [phx_change: :set_input_value, phx_submit: :execute, class: "flex w-full"] %>
                <%= text_input :command, :text, [placeholer: "Write Elixir code to execute and hit 'Enter'...", value: @input_value, class: "w-full px-1 outline-none"] %>
              </form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:put_log, session_id, log}, %{assigns: %{current_session_id: sid}} = socket)
      when session_id == sid do
    {:noreply,
     socket
     |> assign(logs: socket.assigns.logs ++ [log])}
  end

  def handle_info({:put_log, _session_id, _log}, socket) do
    {:noreply, socket}
  end

  def handle_info({:session_ids, session_ids}, socket) do
    if Enum.member?(session_ids, socket.assigns.current_session_id) do
      {:noreply, socket |> assign(session_ids: session_ids)}
    else
      {:noreply, socket |> assign(session_ids: session_ids, current_session_id: nil)}
    end
  end

  @impl true
  def handle_event("set_input_value", %{"command" => %{"text" => command}}, socket) do
    {:noreply, socket |> assign(:input_value, command)}
  end

  def handle_event("execute", %{"command" => %{"text" => command}}, socket) do
    Backdoor.Session.execute(socket.assigns.current_session_id, command)

    {:noreply, socket |> assign(:input_value, "")}
  end

  def handle_event("start_session", %{}, socket) do
    {:ok, _session_id} = Backdoor.Session.start_session()

    {:noreply, socket}
  end

  def handle_event("stop_session", %{"session-id" => sid}, socket) do
    {session_id, ""} = Integer.parse(sid)
    Backdoor.Session.stop_session(session_id)

    if socket.assigns.current_session_id == session_id do
      {:noreply,
       socket
       |> assign(current_session_id: nil, logs: [])}
    else
      {:noreply, socket}
    end
  end

  def handle_event("switch_session", %{"session-id" => sid}, socket) do
    {session_id, ""} = Integer.parse(sid)

    {:noreply,
     socket |> assign(current_session_id: session_id, logs: Backdoor.Session.get_logs(session_id))}
  end

  defp format({:error, kind, error, stack}) do
    Exception.format(kind, error, stack)
  end

  defp format({:input, code}) do
    code
  end

  defp format({:output, code}) do
    code
  end

  defp format({:result, value}) do
    inspect(value)
  end

  defp find_pubsub_server(endpoint) do
    case Application.get_env(:backdoor, :pubsub_server) do
      nil ->
        server = endpoint.config(:pubsub_server) || endpoint.__pubsub_server__()
        Application.put_env(:backdoor, :pubsub_server, server)
        server

      server ->
        server
    end
  end
end
