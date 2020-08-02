# encoding: UTF-8
class TexteItem
class << self
  attr_reader :items

  def init
    @items = []
  end #/ init

  def create(params, offset, index)
    item = new(params[0..1])
    item.canon  = params[2] if item.is_a?(Mot)
    item.offset = offset
    item.index  = index
    send(:on_create, item) if respond_to?(:on_create)
    return item
  end #/ create

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

attr_reader :content, :type
attr_accessor :index, :offset, :canon
attr_accessor :icanon

def initialize(params)
  # Note : sera redéfini par chaque sous-classe
  @content, @type = params
end #/ initialize

def length
  @length ||= content.length + 1
end #/ length

def main_type
  @main_type ||= type.split(':').first
end #/ main_type

def sous_type
  @sous_type ||= type.split(':').last
end #/ sous_type

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
    if ! proximizable?
      @f_length = length
      ' ' * @f_length
    elsif prox_avant.nil? && prox_apres.nil?
      @f_length = length
      ' ' * @f_length
    else
      # dist_avant = prox_avant&.distance&.to_s
      # dist_apres = prox_apres&.distance&.to_s

      dist_avant = nil
      dist_apres = nil
      if prox_avant
        dist_avant = prox_avant.mot_avant.index.to_s
      end
      if prox_apres
        dist_apres = prox_apres.mot_apres.index.to_s
      end

      dist_avant_len = dist_avant&.length || 0
      dist_apres_len = dist_apres&.length || 0
      # Longueur occupée par les distances
      long_proxs = dist_avant_len + dist_apres_len + 1
      # Longueur occupée par le mot
      long_mot = content.length
      # On retourne le texte voulu
      nombre_espaces = long_proxs > long_mot ? 1 : long_mot - (dist_avant_len + dist_apres_len)
      # Utile pour les autres calculs
      @f_length = (long_proxs > long_mot ? long_proxs : long_mot )+ 1
      "#{dist_avant}#{' '*nombre_espaces}#{dist_apres} ".freeze
    end
  end
end #/ f_proximities

# Retourne true si le text-item peut être étudié au niveau de ses proximités
def proximizable?
  return false if non_mot?
  return false if length < 4
  return false if main_type == 'DET' # on passe les déterminants
  return false if main_type == 'PRO' # on passe les pronoms
  return true
end #/ proximizable?

def new_paragraphe?
  content == RC
end #/ new_paragraphe?

# Renvoie l'indice de couleur en fonction des proximités
# Note : pour le moment, on prend la plus grosse mais il sera toujours
# possible plus tard de changer ça et de mettre la couleur pour chaque
# proximité, avant et après
def prox_color
  return nil if no_proximites?
  if prox_avant.nil?
    prox_apres.color
  elsif prox_apres.nil?
    prox_avant.color
  else
    if prox_apres.distance < prox_avant.distance
      prox_apres.color
    else
      prox_avant.color
    end
  end
end #/ prox_color

def no_proximites?
  prox_avant.nil? && prox_apres.nil?
end #/ no_proximites?

def prox_avant
  @prox_avant || calcule_proximites
  @prox_avant
end #/ prox_avant
def prox_apres
  @prox_apres || calcule_proximites
  @prox_apres
end #/ prox_apres
def calcule_proximites
  log("calcule_proximites de #{self.content}/index #{self.index}")
  @prox_avant = nil
  @prox_apres = nil
  # Si le canon ne possède que cet item, il ne peut pas y avoir
  # de proximités.
  return if icanon.nil? || icanon.count == 1
  # On cherche d'abord une éventuelle proximité avant
  idx = index.dup
  distance = 0
  while item = Runner.itexte.items[idx -= 1]
    distance += item.length
    break if distance > icanon.distance_minimale
    if item.canon == canon
      # PROXIMITÉ TROUVÉE !
      @prox_avant = Proximite.new(avant:item, apres:self, distance:distance)
      break
    end
  end
  idx = index.dup
  distance = 1
  while item = Runner.itexte.items[idx += 1]
    if item.canon == canon
      # PROXIMITÉ TROUVÉE !
      @prox_apres = Proximite.new(avant:self, apres:item, distance:distance)
      break
    end
    distance += item.length
    break if distance > icanon.distance_minimale # fini
  end
end #/ calcule_proximites
end #/TexteItem
