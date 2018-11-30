defmodule PingPong do
  def play do
    pid_ping = spawn &loop_ping/0
    pid_pong = spawn &loop_pong/0
    IO.puts "ping-pong start!"
    send pid_ping, {0, pid_pong}
  end

  defp loop_ping do
    receive do
      {ball, caller} ->
        Process.sleep 1000
        next = Enum.random(0..99)
        IO.puts "[ping]> back: #{ball}, next: #{next}."
        send caller, {next, self()}
        loop_ping()
    end
  end
  defp loop_pong do
    receive do
      {ball, caller} ->
        back = ball + 1
        IO.puts "[pong]> received: #{ball}, back #{back}."
        IO.puts ""
        send caller, {back, self()}
        loop_pong()
    end
  end
end
PingPong.play()
Process.sleep :infinity
