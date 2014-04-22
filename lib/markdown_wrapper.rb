require 'maruku'

class MarkdownWrapper
  def to_html(text)
    Maruku.new(fix_indent(text)).to_html
  end

protected

  # Removes all leading whitespace until it finds
  # the first line with no leading whitespace
  def fix_indent(text)
    split_text = text.split(/^([^\s])/, 2)
    return '' if split_text.empty?
    split_text.first.gsub!(/^\s+/, '')
    "#{split_text.first}#{split_text.second}#{split_text.third}"
  end
end
