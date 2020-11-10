defmodule Sentry.FinchClient do
  @moduledoc """
  Defines a small shim to use `Finch` as a `Sentry.HTTPClient`.
  """

  @behaviour Sentry.HTTPClient

  @impl true
  def child_spec do
    Finch.child_spec(name: Sentry.Finch)
  end

  @impl true
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
