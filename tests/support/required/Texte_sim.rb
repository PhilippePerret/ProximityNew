# encoding: UTF-8
=begin
  Simulation de la classe Texte pour les tests
=end
class Texte
  # ---------------------------------------------------------------------
  #
  #   MÉTHODE SIMULÉES
  #
  # ---------------------------------------------------------------------
  attr_reader :path
  def initialize(path)
    @path = path
  end #/ initialize

  def folder
    @folder ||= File.dirname(path)
  end #/ folder
  # ---------------------------------------------------------------------
  #
  #   MÉTHODES FONCTIONNELLE
  #
  # ---------------------------------------------------------------------

end #/Texte
