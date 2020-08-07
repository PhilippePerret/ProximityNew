# encoding: UTF-8
class String

  CHIFFRE_HAUT = {
    0 => '⁰',
    1 => '¹',
    2 => '²',
    3 => '³',
    4 => '⁴',
    5 => '⁵',
    6 => '⁶',
    7 => '⁷',
    8 => '⁸',
    9 => '⁹'
  }

  CHIFFRE_BAS = {
    0 => '₀',
    1 => '₁',
    2 => '₂',
    3 => '₃',
    4 => '₄',
    5 => '₅',
    6 => '₆',
    7 => '₇',
    8 => '₈',
    9 => '₉'
  }

  def self.columnize(lines, delimitor = ',')
    lines = lines.join(RC) if lines.is_a?(Array)
    str = `echo "#{lines}" | column -t -s '#{delimitor}'`
    str.gsub(/([^ \n])  /,'\1     ')
  end

  def collapse
    self.gsub(/([ \t])[ \t]+/,'\1')
  end

  # Le texte en bleu gras pour le terminal
  def bleu_gras
    "\033[1;96m#{self}\033[0m"
  end

  # Le texte en bleu gras pour le terminal
  def bleu
    "\033[0;96m#{self}\033[0m"
    # 96=bleu clair, 93 = jaune, 94/95=mauve, 92=vert
  end

  def mauve
    "\033[1;94m#{self}\033[0m"
  end

  def fond1
    "\033[38;5;8;48;5;45m#{self}\033[0m"
  end

  def fond2
    "\033[38;5;8;48;5;40m#{self}\033[0m"
  end

  def fond3
    "\033[38;5;0;48;5;183m#{self}\033[0m"
  end

  def fond4
    "\033[38;5;15;48;5;197m#{self}\033[0m"
  end

  def fond5
    "\033[38;5;15;48;5;172m#{self}\033[0m"
  end

  def jaune
    "\033[0;93m#{self}\033[0m"
  end
  alias :yellow :jaune

  def vert
    "\033[0;92m#{self}\033[0m"
  end

  # Le texte en rouge gras pour le terminal
  def rouge_gras
    "\033[1;31m#{self}\033[0m"
  end

  # Le texte en rouge gras pour le terminal
  def rouge
    "\033[0;91m#{self}\033[0m"
  end

  def rouge_clair
    "\033[0;35m#{self}\033[0m"
  end

  def gris
    "\033[0;90m#{self}\033[0m"
  end

  def gras
    "\033[1;38m#{self}\033[0m"
  end

  def purple
    "\033[1;34m#{self}\033[0m"
  end

  def yellow
    "\033[1;33m#{self}\033[0m"
  end

  def fushia
    "\033[1;35m#{self}\033[0m"
  end

  def cyan
    "\033[1;36m#{self}\033[0m"
  end

  def grey
    "\033[1;90m#{self}\033[0m"
  end

  # Convertit le texte en colonnes de largeurs +width+
  # Si options[:indent] est fourni, on ajoute cette indentation
  # à chaque ligne.
  def colonnize width = 50, options = nil # en nombre de caractères
    res = `echo "#{self.gsub(/"/,'\\"')}" | fmt #{width}`
    if options && options[:indent]
      res = options[:indent] + res.gsub!(/\n/, "\n#{options[:indent]}")
    end
    return res
  end

end #/Class String
