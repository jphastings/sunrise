defmodule Radio do
    use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    proc = Porcelain.spawn_shell(
      "mpg321 -3 -R sunrise 2>&1",
      in: :receive,
      out: {:send, self()},
      result: :discard
    )
    {:ok, %{proc: proc, status: :stopped}}
  end

  def handle_cast({:change_station, url}, state) do
    Porcelain.Process.send_input(state[:proc], "L #{url}\n")
    {:noreply, %{state | status: :playing}}
  end

  def handle_cast(:pause, state) do
    Porcelain.Process.send_input(state[:proc], "P\n")
    {:noreply, state}
  end

  def handle_call(:status, _from, state) do
    {:reply, state[:status], state}
  end

  def handle_info({pid, :data, :out, data}, state) do
    # Only accept data messages from the mpg321 instance
    state = if (pid == state[:proc].pid) do
      data
      |> String.split("\n", trim: true)
      |> Enum.reduce(state, &parse_mpg321_line/2)
    else
      state
    end
    {:noreply, state}
  end

  defp parse_mpg321_line(line, state) do
    [type | parts] = String.split(line, " ")
    parse_mpg321_line(state, type, parts)
  end

  defp parse_mpg321_line(state, "@S", [_mp3_version, _layer, _sample_rate, _mode_string, _mode_extension, _bytes_per_frame, _channels, _is_copyrighted, _is_crc_protected, _emphasis, _bitrate, _extension]), do: state

  defp parse_mpg321_line(state, "@P", [status_string]) do
    status = case status_string do
      "0" -> :stopped
      "1" -> :paused
      "2" -> :playing
    end
    %{state | status: status}
  end

  defp parse_mpg321_line(state, _key, _parts), do: state
end
