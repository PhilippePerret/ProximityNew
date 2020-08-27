# encoding: UTF-8
=begin
  Simulation des méthodes de CWindow
=end
class CWindow
class << self
  # ---------------------------------------------------------------------
  #
  #   MÉTHODES SIMULÉES
  #
  # ---------------------------------------------------------------------

  # Note : utiliser CWindow.last_log pour obtenir le dernier message de
  # log
  def log(msg)
    @messages_log ||= []
    @messages_log << msg
  end #/ log


  # Les trois parties de l'interface
  def logWind
    @logWind ||= new(:log)
  end #/ logWind

  def textWind
    @textWind ||= new(:text)
  end #/ textWind

  # ---------------------------------------------------------------------
  #
  #   MÉTHODES FONCTIONNELLES
  #
  # ---------------------------------------------------------------------

  def reset
    @messages_log = []
  end #/ reset

  # Retourne le dernier message de log
  def last_log
    (@messages_log || []).last
  end #/ last_log
end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
#
#   MÉTHODES D'INSTANCE SIMULÉES
#
# ---------------------------------------------------------------------

def initalize(type)
  @type = type
  @commandes = [] # pour les tests
end #/ initalize

def clear
  @commandes << :clear
end #/ clear



# ---------------------------------------------------------------------
#
#   MÉTHODES FONCTIONNELLES
#
# ---------------------------------------------------------------------
private
end #/CWindow
