defmodule JSON_Applet do

  defp compile meta do
    curr     = Enum.at(meta.raw, meta.i)
    raw_args = Enum.at(meta.raw, meta[:i] + 1, :none)

    # is it a function call?
    cond do
      meta.i >= Enum.count(meta.raw) ->
        meta

      is_binary(curr) && is_list(raw_args) ->
        raw_block = Enum.at(meta.raw, meta.i+2, :none)

        if is_list(raw_block) do
          meta = %{meta | :i => meta.i + 3}
        else
          meta = %{meta | :i => meta.i + 2}
          raw_block = []
        end

        if !is_function(meta.funcs[curr]) do
          raise "Function not found: #{curr}"
        end

        meta_func = %{
          stack:     meta.stack,
          raw_args:  raw_args,
          raw_block: Enum.reverse(raw_block),
          compile_args: fn() ->
            raw_args
          end,
          compile_block: fn() ->
            raw_block
          end
        }
        meta = %{meta | :stack => meta.funcs[curr].(meta_func)}
        compile(meta)

      true ->
        meta = %{ meta | :i => meta.i + 1, :stack => Enum.into([ curr ], meta.stack)}
        compile(meta)

    end # === cond

  end # === defp compile

  def run raw, funcs \\ [], stack \\ [] do
    json = cond do
      is_binary(raw) -> Poison.decode!(raw)
      is_list(raw) -> raw
      true -> raise "Only String and List are allowed."
    end # === cond

    compile(%{i: 0, raw: json, funcs: funcs, stack: stack}).stack
  end # === def run raw

end # === defmodule JSON_Applet
