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

  def add(titem)
    @items ||= []
    @items << titem
  end #/ add

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

attr_reader :content, :type
attr_accessor :index, :offset, :canon
attr_accessor :icanon

def initialize(content)
  @content = content
  self.class.add(self)
end #/ initialize

# Pour info, le content/index/offset
def cio
  "#{content}/#{index}/#{offset}"
end #/ cio

def to_s
  "Content:'#{content}'/offset:#{offset.inspect}/length:#{length.inspect}/index:#{index.inspect}"
end #/ to_s

def length
  @length ||= content.length
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
# Tous les cas possibles :
#
#   La longueur du mot est suffisante
#
#     123
#     motassezlong
#     121      134
#
#   L'index est plus grand le que le mot sans proximités
#
#     123
#     a
#
#   Les proximités sont plus longues que le mot et que l'index
#
#     123
#     a
#     134|125
#
def f_length
  @f_length
end #/ f_length

# L'index formaté. On ne l'indique pas si c'est une ponctuation.
def f_index(idx)
  (non_mot? ? SPACE : idx).to_s.ljust(f_length)
end #/ f_index

# Pour la deuxième ligne contenant le texte
def f_content
  c = ''
  c << SPACE if f_length - length > 4
  c << content
  c.ljust(f_length)
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
  if !proximizable? || (prox_avant.nil? && prox_apres.nil?)
    ' ' * f_length
  else
    dist_avant = ''
    dist_apres = ''
    if prox_avant
      log("Mot “#{content}” (#{index}/#{offset}) a une proximité AVANT : #{prox_avant.mot_avant.content} (#{prox_avant.mot_avant.index}/#{prox_avant.mot_avant.offset})")
      dist_avant = (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s
    end
    if prox_apres
      log("Mot “#{content}” (#{index}/#{offset}) a une proximité APRÈS : #{prox_apres.mot_apres.content} (#{prox_apres.mot_apres.index}/#{prox_apres.mot_apres.offset})")
      dist_apres = (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s
    end

    dist_avant_len = dist_avant.length || 0
    dist_apres_len = dist_apres.length || 0

    long_dist  = dist_avant_len + dist_apres_len

    moitie_avant = (f_length / 2) - 1 # -1 pour la barre
    moitie_apres = f_length - moitie_avant - 1
    # Utile pour les autres calculs
    if prox_avant && prox_apres
      if "#{dist_avant}|#{dist_apres}".length+1 >= f_length
        "#{dist_avant}|#{dist_apres}".freeze
      else
        "#{dist_avant.ljust(moitie_avant)}|#{dist_apres.rjust(moitie_apres)}".freeze
      end
    elsif prox_avant
      "#{dist_avant}|".ljust(f_length)
    else
      "|#{dist_apres} ".rjust(f_length - 1)
    end
  end
end #/ f_proximities

def calcule_longueurs
  # Longueur occupée par le mot
  long_mot    = length.dup
  long_index  = (index - Runner.iextrait.from_item).to_s.length

  if !proximizable? || ( prox_avant.nil? && prox_apres.nil? )
    # Si ce n'est pas un mot proximizable ou qu'il n'y a pas de proximité
    # on compare juste la longueur de l'index et la longueur du mot
    @f_length = [long_mot, long_index].max
  else
    dist_avant = prox_avant ? (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s : nil
    dist_apres = prox_apres ? (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s : nil

    dist_avant_len = dist_avant&.length || 0
    dist_apres_len = dist_apres&.length || 0

    # Longueur occupée par les distances
    long_dist  = dist_avant_len + dist_apres_len
    long_proxs = long_dist + 1 # +1 pour la barre
    @f_length = [long_index, long_proxs, long_mot].max
  end
end #/ calcule_longueurs

# Retourne true si le text-item peut être étudié au niveau de ses proximités
def proximizable?
  @is_not_proximizabe ||= begin
    if non_mot? || length < 4 || main_type == 'PRO' || main_type == 'DET'
      :false
    else
      :true
    end
  end
  @is_not_proximizabe === :true
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
    if !proximizable? || icanon.nil? || icanon.count == 1
      @prox_avant = nil
    else
      # log("*** Recherche proximité avant de #{cio} ***")
      # log("Offsets du canon #{icanon.canon.inspect} : #{icanon.offsets.inspect}")
      idx_canon = icanon.offsets.index(offset)
      # log("Index du mot courant dans icanon.offsets: #{idx_canon}")
      if idx_canon > 0 # il peut y avoir un mot avant
        # log("Le mot possède un item avant lui")
        prev_item_in_canon = icanon.items[idx_canon - 1]
        # log("Cet item est : #{prev_item_in_canon.cio}")
        distance = offset - prev_item_in_canon.offset
        # log("Ils sont séparés de #{distance}")
        if distance < icanon.distance_minimale
          # log("Ils sont en proximité")
          @prox_avant = Proximite.new(avant:prev_item_in_canon, apres:self, distance:distance)
          prev_item_in_canon.prox_apres = @prox_avant
        end
      else
        # log("C'est le premier offset => pas d'item avant")
      end
    end
    @prox_avant_calculed = true
  end
  @prox_avant
end #/ prox_avant
def prox_avant=(prox); @prox_avant = prox end

def prox_apres
   @prox_apres_calculed || begin
    if !proximizable? || icanon.nil? || icanon.count == 1
      @prox_apres = nil
    else
      # log("*** Recherche proximité APRÈS pour #{cio} ***")
      idx_canon = icanon.offsets.index(offset)
      # log("Index dans icanon.offsets: #{idx_canon}")
      # log("(icanon.offsets = #{icanon.offsets.inspect})")
      next_item_in_canon = icanon.items[idx_canon + 1]
      if next_item_in_canon # il y a un mot après
        # log("Un item a été trouvé après : #{next_item_in_canon.cio}")
        distance = next_item_in_canon.offset - offset
        # log("Distancié de #{distance}")
        if distance < icanon.distance_minimale
          # log("=> Ils sont en proximité")
          @prox_apres = Proximite.new(avant:self, apres:next_item_in_canon, distance:distance)
          next_item_in_canon.prox_avant = @prox_apres
        end
      else
        # log("Pas d'item après")
      end
    end
    @prox_apres_calculed = true
  end
  @prox_apres
end #/ prox_apres

def prox_apres=(prox); @prox_apres = prox end

end #/TexteItem
