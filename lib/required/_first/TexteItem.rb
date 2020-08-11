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

  # Ça sert simplement pour la correspondance entre l'item Mot ici
  # et le mot dans le fichier lemmatisé (même index). Cette liste est
  # remise à zéro chaque fois qu'on traite le texte, donc il ne faut
  # vraiment pas s'appuyer dessus.
  def add(titem)
    @items ||= []
    if titem.is_a?(Array)
      @items += titem
    else
      @items << titem
    end
  end #/ add

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

attr_reader :id
attr_reader :content
attr_accessor :type, :index, :offset, :canon
attr_accessor :icanon

# Cette propriété est mise à true si le mot doit être ignoré des recherches
# de proximité.
attr_accessor :is_ignored

# Pour les projets Scrivener, on enregistre l'identifiant du fichier
# contenant le mot. Le chemin d'accès du fichier peut être retrouvé
# grâce à la méthode ScrivFile.get_path_by_file_id(+file_id+). Cette information
# est enregistrée dans la base SQLite du texte/projet
attr_accessor :file_id # pour les projets Scrivener
# indice du mot (mots seulement) dans le fichier Scrivener correspondant ou
# dans le texte complet lui-même (oui, l'information est également tenue à
# jour pour un simple texte)
# Noter que cet indice est recalculé chaque fois par Texte#recompte, et qu'il
# est donc toujours juste, comme l'offset du mot.
attr_accessor :indice_in_file

# Utile pendant le parsing, pour savoir que dans "m'appelle" par exemple,
# le "m'" doit être "collé" à "appelle" pour que tree-tagger fasse
# son boulot correctement.
attr_accessor :is_colled

# Pour les marques de style des documents Scrivener
# Si le mot possède la marque :mark_scrivener_start, la balise
# <$Scr_Cs::<:mark_scrivener_start>> sera ajouté avant de l'écrire,
# collé à lui, si :mark_scrivener_end est défini, la balise
# <!$Scr_Cs::<:mark_scrivener_end>> sera ajouté après lui, collée à lui
attr_accessor :mark_scrivener_start, :mark_scrivener_end

# +params+ Table de données. Permet d'envoyer des valeurs. L'argument a
# été inauguré pour ajouter des NonMot's fin de paragraphe au cours du
# découpage du texte.
def initialize(content, params = nil)
  @content = content
  self.class.add(self)
  unless params.nil?
    params.each { |k,v| instance_variable_set("@#{k}", v)}
  end
end #/ initialize

def load_from_db
  data = Runner.itexte.db.load_text_item(id)
  data.reverse! # pour poper
  DATA_TABLE_TEXT_ITEMS.each do |dcol|
    next if dcol[:insert] === false
    self.send(dcol[:property_sym].to_sym, data.pop)
  end
end #/ load_from_db

def insert_in_db
  @id = Runner.itexte.db.insert_text_item(db_values)
  # log("@id pour le mot #{content.inspect} : #{id.inspect}")
end #/ save_in_db

def update_offset_and_index
  # log("UPDATE ##{id.inspect.ljust(4)} index:#{index.to_s.ljust(4)} offset:#{offset.to_s.ljust(6)}")
  Runner.itexte.db.update_offset_index_titem(id:id, offset:offset, index:index, indice_in_file:indice_in_file)
end #/ update_offset_and_index

# Pour updater les valeurs +data+ dans la base de données
def update_in_db(data)
  Runner.itexte.db.update_text_item(data.merge!(id: id))
end #/ update_in_db

# @Return les valeurs pour la table text_items
def db_values
  TextSQLite::DATA_TABLE_TEXT_ITEMS.collect do |dcol|
    next if dcol[:insert] === false
    prop = (dcol[:property] || dcol[:name].downcase).to_sym
    self.send(prop)
  end.compact
end #/ db_values

def db_mark_scrivener_start
  mark_scrivener_start.values.join(VG) unless mark_scrivener_start.nil?
end #/ db_mark_scrivener_start

def db_mark_scrivener_end
  mark_scrivener_end.values.join(VG) unless mark_scrivener_end.nil?
end #/ db_mark_scrivener_end

# Méthode appelée avant tout recomptage (donc dès qu'une opération est
# exécutée sur le texte)
# ATTENTION : cette méthode est appelée après la définition des :offset et
# :index, il ne faut donc pas mettre ces propriétés dans cette liste. Ou
# alors placer l'appel à reset autre part, pas dans le recomptage.
def reset
  @f_content  = nil
  @is_not_proximizabe   = nil
  @prox_avant_calculed  = nil
  @prox_avant = nil
  @prox_apres_calculed  = nil
  @prox_apres = nil
  @has_canon_exclu = nil
end #/ reset

# Pour info, le content/index/offset
def cio
  "#{content.gsub(/\n/,'\n').inspect}/#{index}/#{offset}#{"/#{file_id}"unless file_id.nil?}"
end #/ cio

# Pour débugguer le texte item
def debug(options = nil)
  options ||= {}
  if options[:output] == :console
    # Sortie pour la console NewProx
    proxs = []
    proxs << prox_avant if prox_avant
    proxs << prox_apres if prox_apres
    deb = "#{content.inspect} | index absolu : #{index} | offset absolu : #{offset} | canon : #{canon} | proximités : #{proxs.count}"
    deb << " | fichier : #{file_id}" unless file_id.nil?
    deb = deb.freeze
    Debugger.add(deb)
    return deb
  else
    # Sortie pour fichier, formatée pour tenir dans un tableau avec d'autres
    # valeurs
    " #{index.to_s.ljust(7)}#{content.inspect.ljust(15)}#{offset.to_s.ljust(8)}#{file_id.to_s.ljust(7)}"
  end
end #/ debug

def to_s
  "Content:'#{content}'/offset:#{offset.inspect}/length:#{length.inspect}/index:#{index.inspect}"
end #/ to_s

def length
  @length ||= content.length
end #/ length

def main_type
  @main_type ||= begin
    type.split(DEUX_POINTS).first
  rescue Exception => e
    erreur("PROBLÈME AVEC #{self.inspect} : #{e.message}")
    erreur(e)
    raise
  end
end #/ main_type

def sous_type
  @sous_type ||= type.split(DEUX_POINTS).last
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
  @f_content ||= begin
    c = ''
    c << SPACE if f_length - length > 4
    c << content
    c.ljust(f_length)
  end
end #/ f_content

# Retourne le contenu à inscrire dans le fichier reconstitué
# En général, c'est le contenu normal. Mais s'il y a des marques
# de style Scrivener, c'est différent
def content_rebuilt
  c = content
  if mark_scrivener_start
    c.prepend("<$Scr_#{mark_scrivener_start[:lettre]}s::#{mark_scrivener_start[:id]}>".freeze)
  end
  if mark_scrivener_end
    c.prepend("<!$Scr_#{mark_scrivener_end[:lettre]}s::#{mark_scrivener_end[:id]}>".freeze)
  end
  return c
end #/ content_rebuilt

# Méthode qui retourne les proximités formatées
# Les proximités sont calculées dans prox_avant et prox_apres
def f_proximities
  if !proximizable? || (prox_avant.nil? && prox_apres.nil?)
    ' ' * f_length
  else
    dist_avant = ''
    dist_apres = ''
    if prox_avant
      # log("Mot “#{content}” (#{index}/#{offset}) a une proximité AVANT : #{prox_avant.mot_avant.content} (#{prox_avant.mot_avant.index}/#{prox_avant.mot_avant.offset})")
      dist_avant = (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s
    end
    if prox_apres
      # log("Mot “#{content}” (#{index}/#{offset}) a une proximité APRÈS : #{prox_apres.mot_apres.content} (#{prox_apres.mot_apres.index}/#{prox_apres.mot_apres.offset})")
      dist_apres = (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s
    end

    dist_avant_len = dist_avant.length || 0
    dist_apres_len = dist_apres.length || 0

    long_dist  = dist_avant_len + dist_apres_len

    moitie_avant = (f_length / 2) - 1 # -1 pour la barre
    moitie_apres = f_length - moitie_avant - 1
    # Utile pour les autres calculs
    if prox_avant && prox_apres
      if "#{dist_avant}|#{dist_apres}".length >= f_length
        "#{dist_avant}|#{dist_apres}".freeze
      else
        "#{dist_avant.ljust(moitie_avant)}|#{dist_apres.rjust(moitie_apres)}".freeze
      end
    elsif prox_avant
      "#{dist_avant}|".ljust(f_length)
    else
      "|#{dist_apres}".rjust(f_length)
    end
  end
end #/ f_proximities

def calcule_longueurs

  # Longueur occupée par le mot
  if index.nil?
    raise("index du mot #{cio} est nil… impossible normalement")
  elsif Runner.iextrait.from_item.nil?
    raise("Runner.iextrait.from_item est nil (dans le calcul des longueurs de #{cio})… Impossible normalement")
  end
  long_index  = (index - Runner.iextrait.from_item).to_s.length

  if non_mot?
    @f_length = length
  elsif is_colled === true
    @f_length = [length, long_index].max
  elsif !proximizable? || ( prox_avant.nil? && prox_apres.nil? )
    # Si ce n'est pas un mot proximizable ou qu'il n'y a pas de proximité
    # on compare juste la longueur de l'index et la longueur du mot
    @f_length = [length, long_index].max
  else
    dist_avant = prox_avant ? (prox_avant.mot_avant.index - Runner.iextrait.from_item).to_s : nil
    dist_apres = prox_apres ? (prox_apres.mot_apres.index - Runner.iextrait.from_item).to_s : nil

    dist_avant_len = dist_avant&.length || 0
    dist_apres_len = dist_apres&.length || 0

    # Longueur occupée par les distances
    long_dist  = dist_avant_len + dist_apres_len
    long_proxs = long_dist + 1 # +1 pour la barre
    @f_length = [long_index, length, long_proxs].max
  end
end #/ calcule_longueurs

# Retourne true si le text-item peut être étudié au niveau de ses proximités
def proximizable?
  @is_not_proximizabe ||= begin
    if non_mot? || ignored? || length < 4 || icanon.nil? || main_type == 'PRO' || main_type == 'DET' || is_exclu?
      :false
    else
      :true
    end
  end
  @is_not_proximizabe === :true
end #/ proximizable?

def is_exclu?
  @has_canon_exclu ||= begin
    Runner.itexte.liste_mots_sans_prox.key?(canon) ? :true : :false
  end
  @has_canon_exclu == :true
end #/ is_exclu?

def new_paragraphe?
  content == RC
end #/ new_paragraphe?

def space?
  @is_space ||= (non_mot? && content == SPACE) ? :true : :false
  @is_space === :true
end #/ space

def no_proximites?
  prox_avant.nil? && prox_apres.nil?
end #/ no_proximites?

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

def index_in_canon
  icanon.offsets.index(offset)
end #/ index_in_canon

def prox_avant
  @prox_avant_calculed || begin
    if !proximizable? || icanon.nil? || icanon.count == 1 || index_in_canon.nil?
      @prox_avant = nil
    else
      # log("*** Recherche proximité avant de #{cio} ***")
      # log("Offsets du canon #{icanon.canon.inspect} : #{icanon.offsets.inspect}")

      # On cherche l'index du mot courant dans son canon. Pour se faire, on
      # se sert des offsets puisqu'ils sont enregistrés dans le canon.
      # NOTE On pourrait aussi fonctionner avec les identifiants des mots, ce
      # qui serait peut-être plus sûr (mais pour le moment, cet identifiant
      # n'existe pas)
      idx_canon = index_in_canon

      # log("Index du mot courant dans icanon.offsets: #{idx_canon}")
      if idx_canon > 0 # il peut y avoir un mot avant

        # Il ne faut pas prendre en compte un mot non proximizable (par
        # exemple ignoré)
        idx_prev_item = idx_canon.dup
        prev_item_in_canon = nil
        begin
          prev_item_in_canon = icanon.items[ idx_prev_item -= 1 ]
        end while prev_item_in_canon && false == prev_item_in_canon.proximizable?

        unless prev_item_in_canon.nil?
          # log("Cet item est : #{prev_item_in_canon.cio}")
          distance = offset - prev_item_in_canon.offset
          # log("Ils sont séparés de #{distance}")
          if distance < icanon.distance_minimale
            # log("Ils sont en proximité")
            @prox_avant = Proximite.new(avant:prev_item_in_canon, apres:self, distance:distance)
            prev_item_in_canon.prox_apres = @prox_avant
          end
        end #/fin de si l'item précédent existe
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
    if !proximizable? || icanon.nil? || icanon.count == 1 || index_in_canon.nil?
      @prox_apres = nil
    else
      # log("*** Recherche proximité APRÈS pour #{cio} ***")
      idx_canon = index_in_canon

      # Il ne faut pas prendre en compte un mot non proximizable (par
      # exemple ignoré)
      idx_next_item = idx_canon.dup
      next_item_in_canon = nil
      begin
        next_item_in_canon = icanon.items[ idx_next_item += 1 ]
      end while next_item_in_canon && false == next_item_in_canon.proximizable?

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
