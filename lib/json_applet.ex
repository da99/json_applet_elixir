defmodule JSON_Applet do

  def run raw do
    json = cond do
      is_binary(raw) -> Poison.decode!(raw)
      is_list(raw) -> raw
      true -> raise "Only String and List are allowed."
    end # === cond

    json
  end # === def run raw

end # === defmodule JSON_Applet
