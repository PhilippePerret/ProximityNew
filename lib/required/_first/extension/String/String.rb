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
