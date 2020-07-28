defmodule Backdoor.BackdoorLive do
  use Backdoor.Web, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(bindings: [], output: "") }
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="container">
      <h1 class="text-orange-500">Backdoor LiveView is alive!</h1>
    </div>
    """
  end
end
