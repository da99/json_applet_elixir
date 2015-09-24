



defmodule JSON_Applet do

  def args! list, num do
    if num != Enum.count(list) do
      raise ArgumentError, message: "Out of bounds: #{num} != Enum.count( #{inspect list} )"
    end
    list
  end # === def args

  def compile_block meta_func do
    compile(%{meta_func.meta | :raw=>meta_func.raw_block, :stack=>[]}).stack
  end

  def compile_args meta_func do
    compile(%{meta_func.meta | :raw=>meta_func.raw_args, :stack=>[]}).stack
  end

  def args list, num do
    if num < 0 || num > Enum.count(list) do
      raise ArgumentError, message: "Out of bounds: #{num} for #{inspect list}"
    end
    Enum.slice(list, 0, num)
  end # === def args

  defp compile meta do

    head = List.first(meta.raw)
    # is it a function call?
    cond do
      Enum.empty?(meta.raw) ->
        meta

      is_list(head) ->
        {:error, "Func name not specified for args: #{inspect head}"}

      is_binary(head) && is_list(Enum.at(meta.raw, 1)) ->
        [curr | curr_tail]  = meta.raw
        [raw_args | raw_args_tail] = curr_tail

        meta = if is_list(List.first raw_args_tail) do
          [raw_block | raw_block_tail] = raw_args_tail
          %{meta | :raw => raw_block_tail}
        else
          raw_block = []
          %{meta | :raw => raw_args_tail}
        end

        if !is_function(meta.funcs[curr]) do
          raise "Function not found: #{curr}"
        end

        meta_func = %{
          stack:     meta.stack,
          vars:      meta.vars,
          raw_args:  raw_args,
          raw_block: raw_block,
          meta:      meta
        }

        updated_meta = meta.funcs[curr].(meta_func)
        compile %{meta | :stack=>updated_meta.stack, :vars=>updated_meta.vars}

      true ->
        [curr | curr_tail]  = meta.raw
        meta = %{ meta | :raw=> curr_tail, :stack => Enum.into([ curr ], meta.stack)}
        compile(meta)

    end # === cond

  end # === defp compile

  def run raw, funcs \\ [], stack \\ [] do
    json = cond do
      is_binary(raw) -> Poison.decode!(raw)
      is_list(raw) -> raw
      true -> raise "Only String and List are allowed."
    end # === cond

    result = compile(%{vars: %{}, raw: json, origin: json, funcs: funcs, stack: stack})
    cond do
      is_tuple(result) ->
        result
      is_map(result) ->
        result.stack
      true ->
        raise "Programmer Error: Unknown return value: #{inspect result}"
    end
  end # === def run raw

end # === defmodule JSON_Applet



defmodule In do
  def spect(var) do
    if System.get_env("IS_DEV") do
      IO.inspect(var)
    else
      nil
    end
  end # === def spect(var)
end # === defmodule In
