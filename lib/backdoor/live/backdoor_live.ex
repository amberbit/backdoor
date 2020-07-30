defmodule Backdoor.BackdoorLive do
  use Phoenix.LiveView,
    layout: {Backdoor.LayoutView, "live.html"},
    container: {:div, class: "font-sans antialiased h-screen flex"}

  use Backdoor.Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(bindings: [], env: init_env(), output: [])}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="font-sans antialiased h-screen flex w-full">
      <!-- Sidebar: -->
      <div class="flex-none w-1/6 pb-6 hidden md:block">
        Sidebar
      </div>
      <!-- Main column -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <!-- Titlebar -->
        <div class="border-b flex px-6 py-2 items-center flex-none">
          <h3 class="text-grey-darkest mb-1 font-extrabold">Title bar</h3>
        </div>
        <!-- Output -->
        <div class="px-6 py-4 flex-1 overflow-y-scroll">
          <%= for message <- @output do %>
            <div class="flex items-start text-sm">
              <pre><%= message %></pre>
            </div>
          <% end %>
        </div>
        <!-- Input -->
        <div class="pb-6 px-4 flex-none">
          <div class="flex rounded-lg border-2 border-grey overflow-hidden">
            <span class="text-xl text-grey border-r-0 border-grey p-2">
              iex&gt;
            </span>
            <%= f = form_tag "#", [phx_submit: :execute, class: "flex w-full"] %>
              <%= text_input :command, :text, [placeholer: "Write Elixir code to execute and hit 'Enter'...", value: "", class: "w-full px-4 outline-none"] %>
            </form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("execute", %{"command" => %{"text" => command}}, socket) do
    {:ok, ast} = Code.string_to_quoted(command)
    {result, bindings, env} = :elixir.eval_forms(ast, socket.assigns.bindings, socket.assigns.env)

    output = socket.assigns.output ++ ["iex> " <> command] ++ [inspect(result)]

    {:noreply,
     socket
     |> push_event("command", %{text: ""})
     |> assign(bindings: bindings, env: env, output: output)}
  end

  def init_env do
    :elixir.env_for_eval(file: "iex")
  end
end
