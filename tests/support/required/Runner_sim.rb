# encoding: UTF-8
=begin
  Simulation de la classe Runner
=end
class Runner
class << self
  # ---------------------------------------------------------------------
  #
  #   MÉTHODES SIMULÉES
  #
  # ---------------------------------------------------------------------

  def itexte
    @itexte ||= Texte.new(default_texte_path)
  end #/ itexte


  # ---------------------------------------------------------------------
  #
  #   MÉTHODES FONCTIONNELLES
  #
  # ---------------------------------------------------------------------

  def default_texte_path
    @default_texte_path ||= File.expand_path('./asset/exemples/simple_text.txt')
  end #/ default_texte_path
  
end # /<< self
end #/Runner
