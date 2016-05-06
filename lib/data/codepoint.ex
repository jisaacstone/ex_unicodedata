parse_data = fn
  (:codepoint, codepoint) -> String.to_integer(codepoint, 16)

  (:category, "Lu") -> {:letter, :uppercase}
  (:category, "Ll") -> {:letter, :lowercase}
  (:category, "Lt") -> {:letter, :titlecase}
  (:category, "Lm") -> {:letter, :modified}
  (:category, "Lo") -> {:letter, :other}
  (:category, "Mn") -> {:mark, :non_spacing}
  (:category, "Mc") -> {:mark, :spacing_combining}
  (:category, "Me") -> {:mark, :enclosing}
  (:category, "Nd") -> {:number, :decimal_digit}
  (:category, "Nl") -> {:number, :letter}
  (:category, "No") -> {:number, :other}
  (:category, "Zs") -> {:separator, :space}
  (:category, "Zl") -> {:separator, :line}
  (:category, "Zp") -> {:separator, :paragraph}
  (:category, "Cc") -> {:other, :control}
  (:category, "Cf") -> {:other, :format}
  (:category, "Cs") -> {:other, :surrogate}
  (:category, "Co") -> {:other, :private_use}
  (:category, "Cn") -> {:other, :not_assigned}  # unused?
  (:category, "Pc") -> {:punctuation, :connector}
  (:category, "Pd") -> {:punctuation, :dash}
  (:category, "Ps") -> {:punctuation, :open}
  (:category, "Pe") -> {:punctuation, :close}
  (:category, "Pi") -> {:punctuation, :initial_quote}
  (:category, "Pf") -> {:punctuation, :final_quote}
  (:category, "Po") -> {:punctuation, :other}
  (:category, "Sm") -> {:symbol, :math}
  (:category, "Sc") -> {:symbol, :currency}
  (:category, "Sk") -> {:symbol, :modifier}
  (:category, "So") -> {:symbol, :other}

  (:bidirectional, "L") -> :left_to_right
  (:bidirectional, "LRE") -> :left_to_right_embedding
  (:bidirectional, "LRO") -> :left_to_right_override
  (:bidirectional, "R") -> :right_to_left
  (:bidirectional, "AL") -> :right_to_left_arabic
  (:bidirectional, "RLE") -> :right_to_left_embedding
  (:bidirectional, "RLO") -> :right_to_left_override
  (:bidirectional, "PDF") -> :pop_directional_format
  (:bidirectional, "EN") -> :european_number
  (:bidirectional, "ES") -> :european_number_separator
  (:bidirectional, "ET") -> :european_number_terminator
  (:bidirectional, "AN") -> :arabic_number
  (:bidirectional, "CS") -> :common_number_separator
  (:bidirectional, "NSM") -> :non_spacing_mark
  (:bidirectional, "BN") -> :boundary_neutral
  (:bidirectional, "B") -> :paragraph_separator
  (:bidirectional, "S") -> :segment_separator
  (:bidirectional, "WS") -> :whitespace
  (:bidirectional, "ON") -> :other_neutrals

  # Character combining is done by sort order of combining class. Returning
  # `nil` could cause bugs due to erlang comparason ordering, so we default
  # to `0`
  (:combining, "") -> 0
  (:combining, num) -> String.to_integer(num)

  (:decomposition, dcmp) ->
    Enum.reduce(:binary.split(dcmp, " ", [:global]), [], fn
      "<" <> tag, chars ->
        tag_a = :binary.part(tag, 0, byte_size(tag) - 1) |> String.to_atom()
        [tag_a | chars]
      "", chars ->
        chars
      char, chars ->
        [String.to_integer(char, 16) | chars]
    end) |> :lists.reverse()

  (n, v) when n in [:decimal, :digit, :number] and byte_size(v) > 0 -> String.to_integer(v)

  (:mirrored, "Y") -> :true
  (:mirrored, "N") -> :false

  (_, _) -> :nil
end

defmodule UnicodeData.Data do
  @moduledoc :false
  @compile {:debug_info, false}

  data_path = Path.join(__DIR__, "UnicodeData.txt")
  fields = [:codepoint, :name, :category, :class, :bidirectional,
            :decomposition, :decimal, :digit, :numeric, :mirrored]

  recur = fn
    ([], _rest, kw, _r) ->
      struct(UnicodeData, kw)
    ([name|nt], [value|vt], kw, r) ->
      try do
        parse_data.(name, value)
      rescue
        ArgumentError -> r.(nt, vt, kw, r)
      else
        data -> r.(nt, vt, [{name, data} | kw], r)
      end
  end

  parse_data_line = fn(line) ->
    recur.(fields, :binary.split(line, ";", [:global]), [], recur)
  end

  Enum.map File.stream!(data_path), fn(line) ->
    struct = parse_data_line.(line)
    def codepoint(unquote(struct.codepoint)), do: unquote(Macro.escape(struct))
  end
end
