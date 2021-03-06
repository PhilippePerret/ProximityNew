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

# Inauguré pour traiter les mots qui se terminent par une apostrophe avec
# rien derrière (espace), comme par exemple un mot élisé dans un dialogue
# comme "barr' toi". Dans ce cas, si le mot placé dans le fichier des mots
# seuls est "barr'", la lemmatisation va considérer qu'il y a deux mots,
# "barr" et "'". Pour l'éviter, on met le mot sans apostrophe dans cette
# propriété :lemma et on l'utilisera 1) pour l'enregistrement dans le fichier
# des mots seuls ET pour la comparaison.
# Mais au cours du parsing, tous les mots sont réglés pour avoir :lemma
# comme version minuscule pour comparaison.
# Permet de traiter le cas par exemple "Souhait'" (mot coupé dans un dialogue)
# qui produirait deux mots pour TreeTagger ("Souhait" et "'") et qu'il faut
# faut donc écrire "Souhait" dans le fichier des mots seulement.
attr_accessor :lemma

def non_mot? ; false end
def mot? ; true end
def is_mot ; true end
def ponctuation?; false end
def ignored?
  is_ignored === true
end #/ ignored?

end #/Mot < TexteItem
