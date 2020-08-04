# encoding: UTF-8
class Mot < TexteItem
class << self
  # Appelé après la création de l'item
  # Quand c'est un mot, il faut peut-être créer le canon
  def on_create(item)
    Canon.add(item)
  end #/ on_create
end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_accessor :canon

def non_mot? ; false end
def mot? ; true end
def ponctuation?; false end

end #/Mot < TexteItem
