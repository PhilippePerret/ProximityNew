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

end #/CWindow
