# encoding: UTF-8
TIRET = '-'.freeze unless defined?(TIRET)
UNDERSCORE = '_'.freeze unless defined?(UNDERSCORE)
AND = ' AND '.freeze unless defined?(AND)

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
