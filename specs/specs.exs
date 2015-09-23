json = File.read!("specs/specs.json")
        |> Poison.decode!

funcs = []
Enum.scan(json, 1, fn (meta, acc) ->
  it       = meta["it"]
  input    = meta["input"]
  expected = meta["output"]

  actual = JSON_Applet.run(input)

  if actual == expected do
    IO.puts "#{IO.ANSI.green}#{acc}:#{IO.ANSI.reset} #{it}"
  else
    IO.puts "#{IO.ANSI.bright}#{IO.ANSI.red}#{acc}: #{it}#{IO.ANSI.reset}"
    IO.puts "#{inspect actual} #{IO.ANSI.bright}#{IO.ANSI.red}!=#{IO.ANSI.reset} #{inspect expected}"
  end
  acc + 1
end)
