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
    item.offset = offset # peut être null
    item.index  = index  # peut être null
    send(:on_create, item) if respond_to?(:on_create)
    return item
  end #/ create

  # Transforme une ligne lemmatisée (par exemple mot TAB PRP TAB mot) en
  # instance Mot ou NonMot
  def lemma_to_instance(line, cur_offset = nil, cur_index = nil)
    mot, type, canon = line.strip.split(TAB)
    if mot == PARAGRAPHE
      # Marque de nouveau paragraphe
      # On crée un nouveau paragraphe avec les éléments
      NonMot.create([RC, 'paragraphe'], cur_offset, cur_index)
    elsif type == 'SENT' || type == 'PUN'
      # Est-ce une fin de phrase ?
      NonMot.create([mot,type], cur_offset, cur_index)
    else
      Mot.create([mot,type,canon], cur_offset, cur_index)
    end
  end #/ lemma_to_instance

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

def to_s
  "Content:'#{content}'/offset:#{offset.inspect}/length:#{length.inspect}/index:#{index.inspect}"
end #/ to_s

def length
  @length ||= content.length
end #/ length

def pre_required
  if mot?
    SPACE
  else
    EMPTY_STRING
  end
end #/ pre_required

def post_required
  if mot?
    EMPTY_STRING
  else
    EMPTY_STRING
  end
end #/ post_required

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
  @f_length
end #/ f_length

# Pour la première ligne contenant l'index
def f_index(idx)
  SPACE + (non_mot? ? SPACE : idx).to_s.ljust(@f_length)
end #/ f_index

# Pour la deuxième ligne contenant le texte
def f_content
  c = pre_required + content + post_required
  # c.prepend(' ') if f_length > length + 1
  c.ljust(@f_length)
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
  if ! proximizable?
    ' ' * f_length
  elsif prox_avant.nil? && prox_apres.nil?
    ' ' * f_length
  else
    dist_avant = nil
    dist_apres = nil
    if prox_avant
      dist_avant = (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s
    end
    if prox_apres
      dist_apres = (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s
    end

    dist_avant_len = dist_avant&.length || 0
    dist_apres_len = dist_apres&.length || 0

    long_dist  = dist_avant_len + dist_apres_len
    # Utile pour les autres calculs
    "#{dist_avant}#{' '*(f_length - long_dist)}#{dist_apres} ".freeze
  end
end #/ f_proximities

def calcule_longueurs
  if ! proximizable?
    @f_length = length + pre_required.length + post_required.length
  elsif prox_avant.nil? && prox_apres.nil?
    @f_length = length + pre_required.length + post_required.length
  else
    dist_avant = nil
    dist_apres = nil
    if prox_avant
      dist_avant = (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s
    end
    if prox_apres
      dist_apres = (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s
    end

    dist_avant_len = dist_avant&.length || 0
    dist_apres_len = dist_apres&.length || 0

    # Longueur occupée par l'index relatif du mot
    long_index = (index - Runner.iextrait.from_item).to_s.length + 1
    # Longueur occupée par les distances
    long_dist  = dist_avant_len + dist_apres_len
    long_proxs = long_dist + 1
    # Longueur occupée par le mot
    long_mot = content.length + pre_required.length + post_required.length
    long_max = [long_index, long_proxs, long_mot].max
    @f_length = long_max
  end
end #/ calcule_longueurs

# Retourne true si l'item est un mot
def mot?
  self.class.name == "Mot".freeze
end #/ mot?

# Retourne true si l'item est une ponctuation
def ponctuation?
  type == 'PUN' || type == 'SENT'
end #/ ponctuation?

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
  @prox_avant_calculed || begin
    if icanon.nil? || icanon.count == 1
      @prox_avant = nil
    else
      idx_canon = icanon.offsets.index(offset)
      if idx_canon > 0 # il peut y avoir un mot avant
        prev_item_in_canon = icanon.items[idx_canon - 1]
        distance = offset - prev_item_in_canon.offset
        if distance < icanon.distance_minimale
          @prox_avant = Proximite.new(avant:prev_item_in_canon, apres:self, distance:distance)
          prev_item_in_canon.prox_apres = @prox_avant
        end
      end
    end
    @prox_avant_calculed = true
  end
  @prox_avant
end #/ prox_avant
def prox_avant=(prox); @prox_avant = prox end

def prox_apres
   @prox_apres_calculed || begin
    if icanon.nil? || icanon.count == 1
      @prox_apres = nil
    else
      idx_canon = icanon.offsets.index(offset)
      next_item_in_canon = icanon.items[idx_canon + 1]
      if next_item_in_canon # il y a un mot après
        distance = next_item_in_canon.offset - offset
        if distance < icanon.distance_minimale
          @prox_apres = Proximite.new(avant:self, apres:next_item_in_canon, distance:distance)
          next_item_in_canon.prox_avant = @prox_apres
        end
      end
    end
    @prox_apres_calculed = true
  end
  @prox_apres
end #/ prox_apres

def prox_apres=(prox); @prox_apres = prox end

end #/TexteItem
