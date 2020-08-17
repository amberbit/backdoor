defmodule Backdoor.BackdoorLive do
  use Phoenix.LiveView,
    layout: {Backdoor.LayoutView, "live.html"},
    container: {:div, class: "font-sans antialiased h-screen flex"}

  use Backdoor.Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(current_session_id: nil, session_ids: Backdoor.Session.session_ids(), logs: [])}
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
              <%= form_tag "#", [phx_submit: :execute, class: "flex w-full"] %>
                <%= text_input :command, :text, [placeholer: "Write Elixir code to execute and hit 'Enter'...", value: "", class: "w-full px-1 outline-none"] %>
              </form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("execute", %{"command" => %{"text" => command}}, socket) do
    logs = Backdoor.Session.execute(socket.assigns.current_session_id, command)

    {:noreply,
     socket
     |> push_event("command", %{text: ""})
     |> assign(logs: socket.assigns.logs ++ logs)}
  end

  def handle_event("start_session", %{}, socket) do
    {:ok, session_id} = Backdoor.Session.start_session()

    {:noreply, socket |> assign(session_ids: Backdoor.Session.session_ids())}
  end

  def handle_event("stop_session", %{"session-id" => sid}, socket) do
    {session_id, ""} = Integer.parse(sid)
    Backdoor.Session.stop_session(session_id)

    if socket.assigns.current_session_id == session_id do
      {:noreply,
       socket
       |> assign(current_session_id: nil, logs: [], session_ids: Backdoor.Session.session_ids())}
    else
      {:noreply, socket |> assign(session_ids: Backdoor.Session.session_ids())}
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

  defp format({:result, value}) do
    inspect(value)
  end
end
