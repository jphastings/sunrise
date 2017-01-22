defmodule Hue do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    bridge = if opts[:hue_username] == nil do
      Huex.connect(opts[:hue_ip]) |> Huex.authorize("sunrise#sunrise")
    else
      Huex.connect(opts[:hue_ip], opts[:hue_username])
    end

    case bridge.status do
      :ok ->
        if {:error, _} = Huex.info(bridge) do
          {:stop, "IP address given is not a Hue bridge"}
        else
          {:ok, %{bridge: bridge}}
        end
      :error ->
        {:stop, bridge.error["description"]}
    end
  end
end
