defmodule Propagators do
  use Application

  def start(_type, _args) do
    Propagator.Supervisor.start_link
  end
end
