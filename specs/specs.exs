json = File.read!("specs/specs.json")
        |> Poison.decode!

funcs = %{
  "sum" => fn(meta) ->
    sum = Enum.reduce(JSON_Applet.compile_args(meta), 0, fn(v, acc) -> v + acc end)
    %{meta | :stack => Enum.into([sum], meta.stack)}
  end,

  "repeat" => fn(meta) ->
    [num] = JSON_Applet.args!(JSON_Applet.compile_args(meta), 1)
    new_stack = Enum.reduce(1..num, [], fn(x, stack) ->
      Enum.into(JSON_Applet.compile_block(meta), stack)
    end)
    %{meta | :stack => new_stack}
  end,

  "echo" => fn(meta) ->
    args = JSON_Applet.compile_args(meta)
    %{meta | :stack => Enum.into(args, meta.stack)}
  end,

  "var" => fn(meta) ->
    args = JSON_Applet.compile_args(meta)
    case Enum.count(args) do
      1 ->
        [name] = JSON_Applet.args!(args, 1)
        if !Map.has_key?(meta.vars, name) do
          raise ArgumentError, message: "VAR not found: #{inspect name}"
        end
        %{meta | :stack => Enum.into([meta.vars[name]], meta.stack)}
      2 ->
        [name, val] = JSON_Applet.args!(args, 2)
        %{meta | :stack => Enum.into([val], meta.stack), :vars => Map.put(meta.vars, name, val)}
    end
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

  # === If we get a tuple, turn it into a JSON object.
  if (is_tuple(actual)) do
    actual = Poison.decode!(Poison.encode!(Enum.into([actual], %{})))
  end

  cond do
    actual == expected ->
      IO.puts "#{IO.ANSI.green}#{human_index}:#{IO.ANSI.reset} #{it}"
    true ->
      IO.puts "#{IO.ANSI.bright}#{IO.ANSI.red}#{human_index}: #{it}#{IO.ANSI.reset}"
      space = String.duplicate(" ", 2 + String.length to_string(human_index))
      IO.puts "#{space}#{IO.ANSI.bright}#{IO.ANSI.red}#{inspect actual} #{IO.ANSI.bright}#{IO.ANSI.red}!=#{IO.ANSI.reset} #{inspect expected}"

      Process.exit self, "Test failed."
  end
end)
