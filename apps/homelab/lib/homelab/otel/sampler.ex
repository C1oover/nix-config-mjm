defmodule Homelab.Otel.Sampler do
  require OpenTelemetry.Tracer, as: Tracer
  @behaviour :otel_sampler

  @impl :otel_sampler
  def setup(_sampler_opts) do
    []
  end

  @impl :otel_sampler
  def description(_sampler_config) do
    "Homelab.Otel.Sampler"
  end

  @ignored_paths ["/healthz", "/metrics"]

  @impl :otel_sampler
  def should_sample(ctx, _trace_id, _links, _span_name, _span_kind, attributes, _sampler_config) do
    tracestate = Tracer.current_span_ctx(ctx) |> OpenTelemetry.Span.tracestate()

    case Map.get(attributes, :"http.target") not in @ignored_paths do
      true -> {:record_and_sample, [], tracestate}
      false -> {:drop, [], tracestate}
    end
  end
end
