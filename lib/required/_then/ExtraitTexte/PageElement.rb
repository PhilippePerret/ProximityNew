# encoding: UTF-8
=begin
  Structure PageElement
  ---------------------
  Un PageElement est un élément à écrire sur la page. Une page affichée est
  une liste (Array) de PageElement(s)

  :type   Peut-être :finition (pour finir la ligne)
=end
PageElement = Struct.new(:line, :offset, :type, :subject) do
attr_reader :content

def prepare
  prepare_content
  return self # pour simplifier
end #/ prepare

def prepare_content
  @content ||= begin
    case type
    when :titem
      [
        [subject.f_index, CWindow::INDEX_COLOR],
        [subject.f_content, text_color],
        [subject.f_proximities, prox_color]
      ]
    when :finition
      # Quand il s'agit de finir une ligne
      manque = (SPACE * (max_line_length - offset)).freeze
      [[manque],[manque],[manque]]
    when :indent
      [[indentation],[indentation],[indentation]]
    when :blank
      blank_line
    end
  end
end #/ prepare_content
def output
  if content.is_a?(Array)
    content.each_with_index do |segdata, idx|
      segline, color = segdata
      color ||= CWindow::TEXT_COLOR
      CWindow.textWind.writepos([top + idx, left], segline, color)
    end
  else
    CWindow.textWind.writepos([top, left], content, CWindow::TEXT_COLOR)
  end
end #/ out

def top
  @top ||= begin
    case type
    when :titem, :finition
      3 * line + 1 # +1 pour la ligne blanche au-dessus
    when :blank
      line + 1  # +1 pour la ligne blanche au-dessus
    else
      line
    end
  end
end #/ top

def left
  @left ||= begin
    case type
    when :titem, :finition
      offset + ProxPage::LEFT_MARGIN
    else
      offset
    end
  end
end #/ left

def text_color
  case type
  when :titem
    subject.text_color
  else
    CWindow::TEXT_COLOR
  end
end #/ text_color

def prox_color
  case type
  when :titem
    subject.prox_color
  else
    CWindow::TEXT_COLOR
  end
end #/ prox_color

# @Return {String} une ligne vierge qui couvre toute la page
def blank_line
  @blank_line ||= SPACE * max_line_length
end #/ blank_line

def indentation
  @indentation ||= (SPACE * ProxPage::LEFT_MARGIN).freeze
end #/ indentation

def max_line_length
  @max_line_length ||= Runner.iextrait.max_line_length
end #/ max_line_length
end
