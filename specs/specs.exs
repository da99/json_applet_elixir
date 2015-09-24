json = File.read!("specs/specs.json")
        |> Poison.decode!

funcs = %{
  "sum" => fn(meta) ->
    sum = Enum.reduce(meta.compile_args.(), 0, fn(v, acc) -> v + acc end)
    %{meta | :stack => Enum.into([sum], meta.stack)}
  end,

  "repeat" => fn(meta) ->
    0
    meta
  end,

  "echo" => fn(meta) ->
    args = meta.compile_args.()
    %{meta | :stack => Enum.into(args, meta.stack)}
  end,

  "var" => fn(meta) ->
    args = meta.compile_args.()
    [name, val] = JSON_Applet.args!(args, 2)
    %{meta | :stack => Enum.into([val], meta.stack), :vars => Map.put(meta.vars, name, val)}
  end,

  "raw" => fn(meta) ->
    0
    meta
  end
}

Enum.each(Enum.with_index(json), fn ({meta, index}) ->
  it          = meta["it"]
  input       = meta["input"]
  expected    = meta["output"]
  human_index = index + 1

  actual = JSON_Applet.run(input, funcs)

  if actual == expected do
    IO.puts "#{IO.ANSI.green}#{human_index}:#{IO.ANSI.reset} #{it}"
  else
    IO.puts "#{IO.ANSI.bright}#{IO.ANSI.red}#{human_index}: #{it}#{IO.ANSI.reset}"
    space = String.duplicate(" ", 2 + String.length to_string(human_index))
    IO.puts "#{space}#{IO.ANSI.bright}#{IO.ANSI.red}#{inspect actual} #{IO.ANSI.bright}#{IO.ANSI.red}!=#{IO.ANSI.reset} #{inspect expected}"

    Process.exit self, "Test failed."
  end
end)
