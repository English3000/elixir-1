defprotocol IEx.Info do
  @spec info(term) :: [{atom, String.t}]
  def info(term)
end

defimpl IEx.Info, for: Tuple do
  def info(_tuple) do
    ["Data type": "Tuple",
     "Reference modules": "Tuple"]
  end
end

defimpl IEx.Info, for: Atom do
  def info(atom) do
    specific_info = if Code.ensure_loaded?(atom), do: info_module(atom), else: info_atom(atom)
    ["Data type": "Atom"] ++ specific_info
  end

  defp info_module(_mod) do
    ["Reference modules": "Atom, Module"]
  end

  defp info_atom(_atom) do
    ["Reference modules": "Atom"]
  end
end

defimpl IEx.Info, for: List do
  def info(list) do
    specific_info =
      cond do
        list == []                           -> info_list(list)
        :io_lib.printable_unicode_list(list) -> info_char_list(list)
        Keyword.keyword?(list)               -> info_kw_list(list)
        true                                 -> info_list(list)
      end

    ["Data type": "List"] ++ specific_info
  end

  defp info_char_list(char_list) do
    desc = """
    This is a list of integers that is printed as a sequence of codepoints
    delimited by single quotes because all the integers in it represent valid
    UTF-8 characters. Conventionally, such lists of integers are referred to as
    "char lists".
    """

    ["Description": desc,
     "Raw representation": inspect(char_list, char_lists: :as_lists),
     "Reference modules": "List"]
  end

  defp info_kw_list(_kw_list) do
    desc = """
    This is what is referred to as a "keyword list". A keyword list is just a
    list of two-element tuples where the first element of each tuple is an atom.
    """
    ["Description": desc,
     "Reference modules": "List, Keyword"]
  end

  defp info_list(_list) do
    ["Reference modules": "List"]
  end
end

defimpl IEx.Info, for: BitString do
  def info(bitstring) do
    specific_info =
      cond do
        is_binary(bitstring) and String.printable?(bitstring) -> info_string(bitstring)
        is_binary(bitstring)                                  -> info_binary(bitstring)
        is_bitstring(bitstring)                               -> info_bitstring(bitstring)
      end

    ["Data type": "BitString"] ++ specific_info
  end

  defp info_string(bitstring) do
    desc = """
    This is what Elixir refers to as a "String" (which is just a chunk of
    bytes). It's printed surrounded by double quotes because all the bytes in it
    are printable UTF-8 codepoints.
    """
    ["Description": desc,
     "Raw representation": inspect(bitstring, binaries: :as_binaries),
     "Reference modules": "String, :binary"]
  end

  defp info_binary(bitstring) do
    first_non_printable =
      bitstring
      |> String.codepoints()
      |> Enum.find(fn cp -> not String.printable?(cp) end)

    desc = """
    This is a binary. It's printed with the `<<>>` syntax (as opposed to the
    double-quote syntax, like `"foo"`) because it contains non-printable UTF-8
    characters (the first one in the given string is `#{inspect first_non_printable}`.
    """

    ["Description": desc,
     "Reference modules": ":binary"]
  end

  defp info_bitstring(bitstring) do
    desc = """
    This is a bitstring. It's a chunk of bits that are not divisible by 8 (the
    number of bytes isn't whole).
    """

    ["Description": desc]
  end
end

defimpl IEx.Info, for: Integer do
  def info(i) do
    ["Data type": "Integer",
     "Reference modules": "Integer"]
  end
end

defimpl IEx.Info, for: Float do
  def info(i) do
    ["Data type": "Float",
     "Reference modules": "Float"]
  end
end

defimpl IEx.Info, for: Function do
  def info(fun) do
    fun_info = :erlang.fun_info(fun)

    specific_info =
      if fun_info[:module] == :erl_eval do
        info_anon_fun(fun_info)
      else
        info_named_fun(fun_info)
      end

    ["Data type": "Function"] ++ specific_info
  end

  defp info_anon_fun(fun_info) do
    ["Type": to_string(fun_info[:type]),
     "Arity": fun_info[:arity],
     "Description": "This is an anonymous function."]
  end

  defp info_named_fun(fun_info) do
    ["Type": to_string(fun_info[:type]),
     "Name": "#{inspect fun_info[:module]}.#{inspect fun_info.name}",
     "Arity": fun_info[:arity]]
  end
end

defimpl IEx.Info, for: PID do
  def info(pid) do
    ["Data type": "PID",
     "Alive": Process.alive?(pid),
     "Name": process_name(pid),
     "Reference modules": "Process, Node",
     "Description": "Use Process.info/1 for more info about this process"]
  end

  defp process_name(pid) do
    if name = Process.info(pid)[:registered_name] do
      inspect(name)
    else
      "not registered"
    end
  end
end

defimpl IEx.Info, for: Map do
  def info(map) do
    ["Data type": "Map",
     "Reference modules": "Map"]
  end
end

defimpl IEx.Info, for: Port do
  def info(port) do
    port_info = Port.info(port)
    ["Data type": "Port",
     "Open": not is_nil(port_info),
     "Reference modules": "Port"]
  end
end

defimpl IEx.Info, for: Reference do
  def info(ref) do
    ["Data type": "Reference",
     "Reference modules": "Port"]
  end
end
