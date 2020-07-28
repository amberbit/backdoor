defmodule Phoenix.LiveDashboard.ChartComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest
  import Telemetry.Metrics

  alias Phoenix.LiveDashboard.ChartComponent
  @endpoint Phoenix.LiveDashboardTest.Endpoint

  defp render_chart(opts) do
    render_component(ChartComponent, [id: 123] ++ opts)
  end

  describe "rendering" do
    test "counter metric" do
      result = render_chart(metric: counter([:a, :b, :c, :duration]))
      assert result =~ ~s|data-label="Duration"|
      assert result =~ ~s|data-metric="counter"|
      assert result =~ ~s|data-title="a.b.c.duration"|
    end

    test "summary metric" do
      result = render_chart(metric: summary([:a, :b, :c, :count]))
      assert result =~ ~s|data-label="Count"|
      assert result =~ ~s|data-metric="summary"|
      assert result =~ ~s|data-title="a.b.c.count"|
    end

    test "last_value metric" do
      result = render_chart(metric: last_value([:a, :b, :c, :count]))
      assert result =~ ~s|data-label="Count"|
      assert result =~ ~s|data-metric="last_value"|
      assert result =~ ~s|data-title="a.b.c.count"|
    end

    test "adds units" do
      result = render_chart(metric: last_value([:a, :b, :c, :size], unit: :megabyte))
      assert result =~ ~s|data-unit="MB"|

      result = render_chart(metric: last_value([:a, :b, :c, :size], unit: :whatever))
      assert result =~ ~s|data-unit="whatever"|
    end

    test "adds tags to data and title" do
      result = render_chart(metric: last_value([:a, :b, :c, :size], tags: [:foo, :bar]))
      assert result =~ ~s|data-title="a.b.c.size (foo-bar)"|
      assert result =~ ~s|data-tags="foo-bar"|
    end

    test "adds max number of events" do
      result =
        render_chart(
          metric: last_value([:a, :b, :c, :size], reporter_options: [prune_threshold: 5])
        )

      assert result =~ ~s|data-prune-threshold="5"|

      assert_raise ArgumentError, fn ->
        render_chart(
          metric: last_value([:a, :b, :c, :size], reporter_options: [prune_threshold: -1])
        )
      end

      assert_raise ArgumentError, fn ->
        render_chart(
          metric: last_value([:a, :b, :c, :size], reporter_options: [prune_threshold: :infinity])
        )
      end
    end

    test "renders data" do
      result = render_chart(metric: last_value([:a, :b, :c, :count]), data: [{"x", "y", "z"}])
      assert result =~ ~s|<span data-x="x" data-y="y" data-z="z">|

      result = render_chart(metric: last_value([:a, :b, :c, :count]), data: [{nil, "y", "z"}])
      assert result =~ ~s|<span data-x="Count" data-y="y" data-z="z">|
    end

    test "renders a description hint when a description is provided" do
      description = "test description"

      result =
        render_chart(
          metric: last_value([:a, :b, :c, :count], description: description),
          data: [{"x", "y", "z"}]
        )

      assert result =~ description

      result = render_chart(metric: last_value([:a, :b, :c, :count]), data: [{"x", "y", "z"}])
      refute result =~ description
    end
  end
end
