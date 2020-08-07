# encoding: UTF-8
class String

  # Retourne TRUE si le string est un nombre entier
  def integer?
    self.gsub(/[0-9]/,'').empty?
  end #/ integer?

end #/String
