defmodule Phoenix.LiveDashboard.MetricsLive do
  use Phoenix.LiveDashboard.Web, :live_view

  alias Phoenix.LiveDashboard.ChartComponent

  @impl true
  def mount(params, %{"metrics" => {mod, fun}, "metrics_history" => history} = session, socket) do
    all_metrics = apply(mod, fun, [])
    metrics_per_group = Enum.group_by(all_metrics, &group_name/1)

    group = params["group"]
    metrics = metrics_per_group[group]
    {first_group, _} = Enum.at(metrics_per_group, 0, {nil, nil})

    socket =
      socket
      |> assign_mount(:metrics, params, session)
      |> assign(group: group, groups: Map.keys(metrics_per_group))

    cond do
      !socket.assigns.menu.metrics ->
        {:ok,
         push_redirect(socket, to: live_dashboard_path(socket, :home, socket.assigns.menu.node))}

      group && is_nil(metrics) ->
        {:ok, push_redirect(socket, to: live_dashboard_path(socket, :metrics, node()))}

      metrics && connected?(socket) ->
        Phoenix.LiveDashboard.TelemetryListener.listen(socket.assigns.menu.node, metrics)
        send_history_for_metrics(metrics, history)
        {:ok, assign(socket, metrics: Enum.with_index(metrics))}

      first_group && is_nil(group) ->
        path = live_dashboard_path(socket, :metrics, socket.assigns.menu.node, group: first_group)
        {:ok, push_redirect(socket, to: path)}

      true ->
        {:ok, assign(socket, metrics: nil)}
    end
  end

  defp group_name(metric) do
    to_string(metric.reporter_options[:group] || hd(metric.name))
  end

  defp format_group_name("vm"), do: "VM"
  defp format_group_name(group), do: Phoenix.Naming.camelize(group)

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign_params(socket, params)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div class="row">
      <div class="container">
        <ul class="nav nav-tabs mb-4 charts-nav">
          <%= for group <- @groups do %>
            <li class="nav-item">
              <%= live_redirect(format_group_name(group),
                    to: live_dashboard_path(@socket, :metrics, @menu.node, group: group),
                    class: "nav-link #{if @group == group, do: "active"}") %>
            </li>
          <% end %>
        </ul>
      </div>
    </div>

    <%= if @metrics do %>
      <div class="phx-dashboard-metrics-grid row">
      <%= for {metric, id} <- @metrics do %>
        <%= live_component @socket, ChartComponent, id: id, metric: metric %>
      <% end %>
      </div>
    <% end %>
    """
  end

  defp send_updates_for_entries(entries) do
    for {id, label, measurement, time} <- entries do
      data = [{label, measurement, time}]
      send_update(ChartComponent, id: id, data: data)
    end
  end

  @impl true
  def handle_info({:telemetry, entries}, socket) do
    send_updates_for_entries(entries)
    {:noreply, socket}
  end

  def handle_info({:node_redirect, node}, socket) do
    params = if group = socket.assigns.group, do: [group: group], else: []
    {:noreply, push_redirect(socket, to: live_dashboard_path(socket, :metrics, node, params))}
  end

  defp send_history_for_metrics(_, nil), do: :noop

  defp send_history_for_metrics(metrics, history) do
    for {metric, id} <- Enum.with_index(metrics) do
      metric
      |> history_for(id, history)
      |> send_updates_for_entries()
    end
  end

  defp history_for(metric, id, {module, function, opts}) do
    history = apply(module, function, [metric | opts])

    for %{label: label, measurement: measurement, time: time} <- history do
      {id, label, measurement, time}
    end
  end
end
