# encoding: UTF-8
=begin
  Méthodes de substitution quand on teste individuellement les modules
  avec RSpec par exemple, dans le dossier spec
=end
class TestsLog
class << self
  def reset
    @messages = []
    @errors   = []
  end #/ reset
  # Ajouter un message normal
  def add(msg)
    @messages ||= []
    @messages << msg
  end #/ add
  def add_error(msg)
    @errors ||= []
    @errors << msg
  end #/ add_error
  # Retourne le dernier message normal
  def last
    (@messages||[]).last
  end #/ last
  # Retourne le dernier message d'erreur
  def last_error
    (@errors || []).last
  end #/ last_error
end # /<< self

end #/TestsLog

# Pour vérifier un message d'erreur dans les tests
def message_derreur
  TestsLog.last_error
end #/ message_derreur

def log(msg)
  @testlog = msg
end #/ log

def erreur(msg)
  TestsLog.add_error(msg)
end #/ erreur
