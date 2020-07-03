defmodule Tune.Spotify.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: Tune.Spotify.SessionRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Tune.Spotify.SessionSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def ensure_session(id, credentials) do
    case start_session(id, credentials) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error
    end
  end

  defp start_session(id, credentials) do
    DynamicSupervisor.start_child(
      Tune.Spotify.SessionSupervisor,
      {Tune.Spotify.Session, {id, credentials}}
    )
  end
end
