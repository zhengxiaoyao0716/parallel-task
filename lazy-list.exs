#region Emulate Channel

defmodule Channel do
  defstruct [:in, :out]

  def make(bufsize) do
    {:ok, pid_in} = Task.start_link(fn -> loop_in(bufsize) end)
    {:ok, pid_out} = Task.start_link(fn -> loop_out() end)
    %Channel{in: pid_in, out: pid_out}
  end
  def make(), do: make(0)

  defp loop_in(bufsize) do
    receive do
      {:put, data, pid_out, sender} ->
        send pid_out, {:pipe, data, self(), sender}
        if bufsize >= 0 do
          send sender, {:channel_put_ok}
        end
        loop_in(bufsize - 1)
      {:pipe_ok, sender} ->
        if bufsize < -1 do
          send sender, {:channel_put_ok}
        end
        loop_in(bufsize + 1)
    end
  end
  defp loop_out() do
    receive do
      {:get, receiver} ->
        receive do
          {:pipe, data, pid_in, sender} -> 
            send receiver, {:channel_get_ok, data}
            send pid_in, {:pipe_ok, sender}
            loop_out()
        end
    end
  end

  def put(%Channel{in: pid_in, out: pid_out}, data) do
    send pid_in, {:put, data, pid_out, self()}
    receive do: ({:channel_put_ok} -> nil)
  end
  def get(%Channel{out: pid_out}, action) do
    send pid_out, {:get, self()}
    receive do: ({:channel_get_ok, data} -> action.(data))
  end
end
#endregion

defmodule LazyList do
  defstruct channel: nil

  def new(init, iterator) do
    ch = Channel.make(3)
    {:ok, _} = Task.start_link(fn -> yield(ch, init, iterator) end)
    %LazyList{channel: ch}
  end

  defp yield(ch, next, iterator) do
    IO.puts "> before yield: #{next}"
    Channel.put(ch, next)
    IO.puts "< after yield: #{next}"
    yield(ch, iterator.(next), iterator)
  end
  def get(%LazyList{channel: ch}, action) do
      Channel.get(ch, action)
  end
end

infinite_list = LazyList.new(0, &(1+&1))
0..5 |> Enum.each(fn _ ->
  LazyList.get infinite_list, fn
    num -> IO.puts "[received]: #{num}"
  end
end)
Process.sleep 100 # blocked 100ms to watch the channel buffer.
