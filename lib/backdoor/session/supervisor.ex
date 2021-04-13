defmodule Backdoor.Session.Supervisor do
  use Supervisor
  import Backdoor.Session.ViaTuple

  def start_link(session_id) do
    Supervisor.start_link(__MODULE__, session_id, name: via_tuple(__MODULE__, session_id))
  end

  def init(session_id) do
    children = [
      {Backdoor.Session.Log, [name: via_tuple(Backdoor.Session.Log, session_id)]},
      {Backdoor.Session.CaptureOutput,
       [session_id, name: via_tuple(Backdoor.Session.CaptureOutput, session_id)]},
      {Backdoor.Session.CodeRunner,
       [session_id, name: via_tuple(Backdoor.Session.CodeRunner, session_id)]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
