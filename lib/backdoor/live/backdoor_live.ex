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
      <div class="flex flex-col w-1/6 hidden md:block p-4">
        <nav class="space-y-1" aria-label="Sidebar">
          <div class="text-gray-600 group flex items-center px-3 py-2 text-sm font-medium rounded-md">
            <span class="truncate uppercase">
              Elixir shell sessions
            </span>
          </div>

          <%= for session_id <- @session_ids do %>
            <%= if session_id == @current_session_id do %>
              <%= link to: "#", class: "float-right opacity-50 hover:opacity-60", phx_click: :stop_session, phx_value_session_id: session_id do %>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mt-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              <% end %>

              <span class="bg-gray-100 text-gray-900 flex items-center px-3 py-2 text-sm font-medium rounded-md" aria-current="page">
                <span class="truncate">
                  <%= "##{session_id}" %>
                </span>
              </span>
            <% else %>
              <%= link to: "#", class: "float-right opacity-50 hover:opacity-60", phx_click: :stop_session, phx_value_session_id: session_id do %>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mt-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              <% end %>
              <%= link "##{session_id}", to: "#", phx_click: :switch_session, phx_value_session_id: session_id, class: "text-gray-600 hover:bg-gray-50 hover:text-gray-900 flex items-center px-3 py-2 text-sm font-medium rounded-md" %>
            <% end %>
          <% end %>
        </nav>

        <%= link "New session", to: "#", phx_click: :start_session, class: "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded flex flex-grow justify-center my-4" %>

      </div>
      <!-- Main column -->
      <%= if @current_session_id do %>
        <div class="flex-1 flex flex-col overflow-hidden">
          <!-- Titlebar -->
          <div class="border-b flex px-6 py-2 items-center flex-none">
            <h3 class="text-grey-darkest mb-1 font-extrabold">Session: #<%= @current_session_id %></h3>
          </div>
          <!-- Output -->
          <div class="ml-4 pl-1 pr-0 pt-4 overflow-y-scroll flex flex-grow flex-col-reverse bg-dracula" phx-hook="ScrollToBottom" phx-update="prepend" id="logs">
            <%= for %{id: id, value: value} <- @logs do %>
              <div class="flex items-start text-sm" id="<%= id %>">
                <%= format(id, value) %>
              </div>
            <% end %>
          </div>
          <!-- Input -->
          <div class="px-4 my-2 flex-none" phx-update="ignore">
            <div class="flex editor language-elixir" phx-hook="EditorInput" id="editor-input"></div>
          </div>
          <div class="pb-6 px-4 flex-none">
            <%= if !is_executing?(@current_session_id, @logs) do %>
              <a href="#" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 flex flex-grow justify-center my-4" phx-click="execute" title="You can also hit Ctrl+Enter or Command+Enter">Execute</a>
            <% else %>
              <a href="#" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 flex flex-grow justify-center my-4" title="The code is currently executing">Executing...</a>
            <% end %>
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
     |> assign(logs: [log | socket.assigns.logs])}
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

  def handle_info({_ref, :pong}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("set_input_value", %{"command" => %{"text" => command}}, socket) do
    {:noreply, socket |> assign(:input_value, command)}
  end

  def handle_event("execute", _, socket) do
    if Backdoor.Session.is_executing?(socket.assigns.current_session_id) do
      socket
    else
      socket.assigns.current_session_id
      |> Backdoor.Session.execute(socket.assigns.input_value)

      socket
      |> assign(:input_value, "")
      |> push_event("new_input_value", %{"command" => %{"text" => ""}})
      |> push_event("scroll_to_bottom", %{})
    end
    |> into_tuple(:noreply)
  end

  def handle_event("start_session", %{}, socket) do
    {:ok, session_id} = Backdoor.Session.start_session()

    {:noreply, socket |> assign(current_session_id: session_id)}
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

  defp format(id, {:error, kind, error, stack}) do
    assigns = %{id: id, kind: kind, error: error, stack: stack}

    ~L"""
    <div class="bg-dracula logged-error text-white" title="Error">
      <pre id="<%= @id %>-inner"><%= Exception.format(@kind, @error, @stack) %></pre>
    </div>
    """
  end

  defp format(id, {:input, code}) do
    assigns = %{id: id, code: code}

    ~L"""
    <div class="bg-dracula w-full logged-input" phx-update="ignore" title="Executed code">
      <pre id="<%= @id %>-inner" phx-hook="Highlight"><%= @code %></pre>
    </div>
    """
  end

  defp format(id, {:output, text}) do
    assigns = %{id: id, text: text}

    ~L"""
    <div class="bg-dracula w-full text-white logged-output" title="Console text output">
      <pre id="<%= @id %>-inner" class="hljs"><%= @text %></pre>
    </div>
    """
  end

  defp format(id, {:result, value}) do
    format(id, value)
  end

  defp format(id, %{level: level, meta: _, msg: {type, msg}} = _value) do
    log_line =
      case type do
        :string -> msg
        _ -> inspect(msg, pretty: true)
      end

    assigns = %{id: id, code: "[#{level}] #{log_line}"}

    ~L"""
    <div class="bg-black w-full text-white logged-log" phx-update="ignore" title="Logger statement">
      <pre id="<%= @id %>-inner" phx-hook="Highlight" class="language-elixir"><%= @code %></pre>
    </div>
    """
  end

  defp format(id, value) do
    assigns = %{id: id, code: inspect(value, pretty: true)}

    ~L"""
    <div class="bg-black w-full text-white logged-value" phx-update="ignore" title="Return value">
      <pre id="<%= @id %>-inner" phx-hook="Highlight" class="language-elixir"><%= @code %></pre>
    </div>
    """
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

  defp is_executing?(session_id, _) do
    Backdoor.Session.is_executing?(session_id)
  end

  defp into_tuple(value, first_element) do
    {first_element, value}
  end
end
