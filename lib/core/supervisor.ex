defmodule Propagator.Supervisor do
  use Supervisor
  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Propagator.Counter, [NameCounter])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
