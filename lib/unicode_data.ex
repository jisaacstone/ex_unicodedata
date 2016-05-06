defmodule UnicodeData do
  defstruct codepoint: nil, name: nil, category: nil, combining: 0,
            bidirectional: nil, decomposition: nil, mirrored: nil,
            decimal: nil, digit: nil, numeric: nil
  def codepoint(<<cp::utf8>>), do: codepoint(cp)
  def codepoint(cp) when is_number(cp) and cp >= 0 do
    UnicodeData.Data.codepoint(cp)
  end
end
