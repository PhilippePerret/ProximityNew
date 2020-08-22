# encoding: UTF-8
TIRET             = '-'.freeze unless defined?(TIRET)
TIRET_DIALOGUE    = '–'.freeze unless defined?(TIRET_DIALOGUE)
UNDERSCORE        = '_'.freeze unless defined?(UNDERSCORE)
AND               = ' AND '.freeze unless defined?(AND)
CHEVRON_OPEN      = '«'.freeze unless defined?(CHEVRON_OPEN)
GUIL              = '"'.freeze unless defined?(GUIL)
GUIL_COURBE_OPEN  = '“'.freeze unless defined?(GUIL_COURBE_OPEN)

# Les premiers signes qui peuvent commencer une phrase.
FIRST_SIGN_PHRASE = {
  TIRET_DIALOGUE => true,
  CHEVRON_OPEN => true,
  GUIL => true,
  GUIL_COURBE_OPEN => true,
}

class String

  # Tronçonne le texte +texte+ en portions dont la longueur maximale
  # doit être +maxlen+
  # @Return liste des portions de texte obtenues
  # Plus tard, les +options+ permettront par exemple de définir les caractères
  # délimiteurs.
  # Stratégie :
  #   - je prends un segment de la longueur +maxlen+ dans le +texte+
  #   - je cherche le délimiteur de phrase se trouvant le plus proche de
  #     maxlen dans ce segment
  #   - je découpe le texte à ce délimiteur et je poursuis
  # Je commence
  def self.tronconne(texte, maxlen, options = nil)
    segments = []
    while seg = texte[0...maxlen].strip
      if seg.length < maxlen
        segments << seg.strip
        break
      end
      i = -1
      while ( o = seg.index(/[ .?!…;,]/, maxlen - ( i += 1 ))).nil?; end
      segments << seg[0..o].strip
      texte = texte[o..-1]
    end
    return segments
  end #/ tronconne

  # Retourne TRUE si le string est un nombre entier
  def integer?
    self.gsub(/[0-9]/,'').empty?
  end #/ integer?


  def decamelize
    res = self.split(/([A-Z])/).reverse
    res.pop if res.last.empty?
    seg = []
    while maj = res.pop
      min = res.pop
      seg << "#{maj.downcase}#{min}"
    end
    seg.join(UNDERSCORE)
  end #/ decamelize

end #/String
