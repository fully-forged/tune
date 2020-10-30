defmodule Sentry.FinchClient do
  @moduledoc """
  Defines a small shim to use `Finch` as a `Sentry.HTTPClient`.
  """

  @behaviour Sentry.HTTPClient

  def child_spec do
    opts = [name: Sentry.Finch]

    Supervisor.child_spec(
      %{
        id: __MODULE__,
        start: {Finch, :start_link, [opts]},
        type: :supervisor
      },
      []
    )
  end

  def post(url, headers, body) do
    request = Finch.build(:post, url, headers, body)

    case Finch.request(request, Sentry.Finch) do
      {:ok, response} ->
        {:ok, response.status, response.headers, response.body}

      error ->
        error
    end
  end
end
