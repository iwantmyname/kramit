defmodule Kramit.Html5Renderer do
  def render(markdown) do
    markdown
    |> process_into_lines()
    |> process_meta_values([])
    |> recombine()
  end

  defp process_meta_values() do
    String.split(markdown, "\n", trim: true)
  end

  defp process_meta_values([line | rest], checked_lines) do
    cond do
      has_toc?(line) -> parse_values({:scanning_toc, rest, [ line | checked_lines], ["<nav class="table-of-contents">\n"]})
      true          -> parse_values(rest, [line | checked_lines])
    end
  end


  """
  Scanning for toc state
  """
  defp process_meta_values({:scanning_toc, [<<"## " :: line::binary>> | rest], [checked_lines], [nav]}) do
    handled_line = line
      |> String.downcase
      |> String.replace(" ", "-")
    process_meta_values({:scanning_toc, rest, [ "## " <> line | checked_lines], [ "<li><a href=##{parsed_line}> #{line} </a></li>" | nav]})
  end

  defp process_meta_values({:scanning_toc, [line | rest], [checked_lines]}, [nav]) do
    process_meta_values({:scanning_toc, rest, [line | checked_lines], [nav]})
  end

  defp process_meta_values({:scanning_toc, ["#endtoc" | rest], [checked_lines], [nav] }) do
    process_meta_values({:find_end_of_doc_for_toc, [line | checked_lines], [nav])
  end

  """
  Fast Forward
  """
  defp process_meta_values({:find_end_of_doc_for_toc, [line | rest], [checked_lines], [nav] }) do
    process_meta_values({:find_end_of_doc_for_toc, rest , [line | checked_lines], [nav])
  end

  defp process_meta_values({:find_end_of_doc_for_toc, [], [checked_lines], [nav] }) do
    process_meta_values({:scanning_toc, [] , [ "#endtoc" | checked_lines], [nav])
  end

  """
  Finish Scan
  """
  defp process_meta_values({:scanning_toc, [], [checked_lines], [nav] }) do
    toc = ["</nav>" | nav]
    |> Enum.reverse()
    process_meta_values({:building_toc, {:toc, toc}, [checked_lines], [] })
  end

  """
  Building toc state
  """

  defp process_meta_values({:building_toc}, {:toc, toc}, ["#endtoc" | rest], [parsed_lines]) do
    process_meta_values({:building_toc}, {:toc, toc}, [rest], [ "</section>" | parsed_lines])
  end

  defp process_meta_values({:building_toc}, {:toc, toc}, [<<"## ", h2_heading::binary>> | rest], [parsed_lines]) do
    id = h2_heading
         |> String.downcase
         |> String.replace(" ", "-")

    cond do
       is_first?(toc, id) -> table_of_contents_item = "<section id=##{id}>\n <h2>#{h2_heading}</h2>\n"
       true               -> table_of_contents_item = "</section><section id=##{id}>\n <h2>#{h2_heading}</h2>\n"
    end
    process_meta_values({:building_toc}, {:toc, toc}, [rest], [table_of_contents_item | parsed_lines])
  end

  defp process_meta_values({:building_toc}, {:toc, toc}, [line | rest], [parsed_lines]) do
    process_meta_values({:building_toc}, {:toc, toc}, [rest], [line | parsed_lines])
  end
  """
  Inquistor functions
  """

  defp has_toc?(line) do
    line = "#toc"
  end

  defp is_first?([ _ | toc_rest], id) do
    #super super junky must figure out better solution after moar coffee
    hd(toc_rest) = <<"<li><a href=\"", rest::binary>>
    String.starts_with?(rest, id)
  end
end