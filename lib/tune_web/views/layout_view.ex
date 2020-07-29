defmodule TuneWeb.LayoutView do
  @moduledoc false
  use TuneWeb, :view

  def authenticated?(conn) do
    Map.get(conn.assigns, :user) !== nil
  end
end
