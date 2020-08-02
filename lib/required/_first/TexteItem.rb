# encoding: UTF-8
class TexteItem
class << self
  attr_reader :items

  def init
    @items = []
  end #/ init

  def create(params, offset)
    item = new(params[0..1])
    item.canon = params[2] if item.is_a?(Mot)
    item.offset = offset
    send(:on_create, item) if respond_to?(:on_create)
    return item
  end #/ create

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

attr_reader :content, :type, :canon
# Index dans la liste des items principaux (items du parent)
attr_accessor :index, :offset
def initialize(params)
  # Note : sera redéfini par chaque sous-classe
  @content, @type = params
end #/ initialize

# Retourne le décalage de l'item (paragraphe, phrase, mot, non-mot) par
# rapport au début du texte. Cet offset doit toujours être calculé
def offset
  @offset ||= begin
    parent.offset + pre_items_length
  end
end #/ offset

def length
  @length ||= content.length + 1
end #/ length

# La longueur "formatée", c'est-à-dire lorsque le mot doit être
# inscrit dans la fenêtre de terminal, avec son index (dans l'extrait) et
# ses distances avec les autres mots.
def f_length
  @f_length || f_proximities
  @f_length
end #/ f_length

# Pour la première ligne contenant l'index
def f_index(idx)
  @f_length || f_proximities
  (non_mot? ? SPACE : idx).to_s.ljust(@f_length)
end #/ f_index

# Pour la deuxième ligne contenant le texte
def f_content
  @f_length || f_proximities
  content.prepend(' ') if f_length > length
  content.ljust(@f_length)
end #/ f_content

# Méthode qui retourne les proximités formatées
# La méthode permet aussi de connaitre la vraie longueur que le mot va
# occuper dans l'affichage, en fonction de sa longueur et de ses distances.
# Par exemple…
#     mot
#   234 1300
# … est un mot de 3 lettres qui occupe 8 lettres. La longueur occupée est
# soit la longueur du mot, soit la longueur de ses deux proximités (if any)
# côte à côté.
# Noter aussi que dans le cas de ce 'mot', le mot commence avec un décalage
# de 2 (pour être sur le 4)
def f_proximities
  @f_proximities ||= begin
    # D'abord on doit récupérer les proximités du mot
    # TODO
    unless proximizable?
      @f_length = length
      ' ' * @f_length
    else
      prox_avant = 23.to_s
      prox_apres = 893.to_s

      prox_avant_len = prox_avant&.length || 0
      prox_apres_len = prox_apres&.length || 0
      # Longueur occupée par les distances
      long_proxs = prox_avant_len + prox_apres_len + 1
      # Longueur occupée par le mot
      long_mot = content.length
      # On retourne le texte voulu
      nombre_espaces = long_proxs > long_mot ? 1 : long_mot - (prox_avant_len + prox_apres_len)
      # Utile pour les autres calculs
      @f_length = (long_proxs > long_mot ? long_proxs : long_mot )+ 1
      "#{prox_avant}#{' '*nombre_espaces}#{prox_apres} ".freeze
    end
  end
end #/ f_proximities

# Retourne true si le text-item peut être étudié au niveau de ses proximités
def proximizable?
  return false if non_mot?
  return false if length < 4
  return true
end #/ proximizable?

def new_paragraphe?
  content == RC
end #/ new_paragraphe?


end #/TexteItem
