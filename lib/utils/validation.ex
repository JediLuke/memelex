defmodule Memex.Utils.Validation do
      
  def validate_tag_list!([]) do
    true
  end

  def validate_tag_list!([tag|rest]) when is_bitstring(tag) do
    validate_tag_list!(rest)
  end

  def validate_tag_list!([tag|_rest]) do # matches anything besides a string 
    context = %{invalid_tag: tag}
    raise "an invalid tag was passed in via the tag list. #{inspect context}"
  end
  
end