defmodule TuneWeb.LayoutView do
  @moduledoc false
  use TuneWeb, :view

  defp authenticated?(conn) do
    conn.assigns.status == :authenticated
  end
end
