defmodule Eximap.Imap.Response do
  @moduledoc ~S"""
  Parse responses returned by the IMAP server and convert them to a structured format
  """
  alias Eximap.Imap.Response
  defstruct request: nil, body: [], status: "OK", error: nil, message: nil

  def parse(resp, []), do: resp

  def parse(resp, lines) do
    {{status, message}, body} = if String.starts_with?(hd(lines), resp.request.tag) do
      {parse_tagged_line(hd(lines)), parse_untagged_lines(tl(lines))}
    else
      {{nil, nil }, parse_untagged_lines(lines)}
    end

    %Response{ resp | status: status, message: message, body: body }
  end

  def parse_tagged_line(line) do
    [_tag, status, body] = String.split(line, " ", parts: 3)
    {status, body}
  end

  def parse_untagged_lines(lines) do
    lines
    |> Enum.reverse()
    |> Enum.map(fn "* " <> line ->
      line = String.trim_trailing(line, "\r\n")
      {type, msg} = case String.split(line, " ", parts: 2) do
        [type | [msg]] -> {type, msg}
        [type] -> {type, nil}
      end
      %{type: type, message: msg}
    end)
  end
end
