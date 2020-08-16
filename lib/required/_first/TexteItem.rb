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

  # Pour instancier si nécessaire un text-item avec ses données
  # En fonction de hdata["IsMot"] on fera des Mot ou des NonMot.
  def instantiate(hdata, index_in_extrait = nil)
    # log("TexteItem::instantiate(hdata:#{hdata.inspect})")
    hdata.each do |k, v|
      begin
        hdata[k] = case v
        when "TRUE"   then true
        when "FALSE"  then false
        else v
        end
      rescue Exception => e
        erreur("Problème avec TexteItem.instantiate avec les données envoyées")
        log("Données transmises : hdata:#{hdata.inspect}, index_in_extrait: #{index_in_extrait.inspect}")
        erreur(e)
        raise "Abandon obligatoire"
      end
    end
    if hdata['IsMot']
      Mot.new(hdata.delete('Content'), hdata)
    else
      NonMot.new(hdata.delete('Content'), hdata)
    end.tap { |i| i.index_in_extrait = index_in_extrait }
  end #/ instantiate
  alias :instanciate :instantiate

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

# Index du text-item (mot ou non nom) dans l'extrait affiché
attr_accessor :index_in_extrait

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
    params.each { |k,v| instance_variable_set("@#{k.to_s.decamelize}", v)}
  end
  self.index = @idx # Idx dans la base de données
end #/ initialize

# Pour info, le content/index/offset
def cio
  "“““#{content.gsub(/\n/,'\n')}”””/##{id}/#{index}/offset-extrait:#{index_in_extrait}/#{offset}#{"/#{file_id}" unless file_id.nil?}"
end #/ cio


def load_from_db
  data = Runner.itexte.db.load_text_item(id)
  data.reverse! # pour pop(er)
  DATA_TABLE_TEXT_ITEMS.each do |dcol|
    next if dcol[:insert] === false
    self.send(dcol[:property_sym].to_sym, data.pop)
  end
end #/ load_from_db

# @Return le mot canon du mot courant
# Note : la méthode le cherche non pas dans la table `lemmas` du texte
# mais dans la table `lemmas` de l'application.
def get_data_canon
  Runner.db.get_canon(content)
end #/ get_data_canon

def icanon
  @icanon ||= Canon[canon]
end #/ icanon
def icanon=(v)
  @icanon = v
end #/ icanon=

def insert_in_db
  # log("Insert in db de : #{db_values.inspect}")
  @id = Runner.itexte.db.insert_text_item(db_values)
  # log("@id pour le mot #{content.inspect} : #{id.inspect}")
end #/ insert_in_db

def get_is_mot
  mot? ? 'TRUE' : 'FALSE'
end #/ get_is_mot
def set_is_mot(v)
  @is_mot = v == 'TRUE'
end #/ set_is_mot
def get_is_ignored
  ignored? ? 'TRUE' : 'FALSE'
end #/ get_is_ignored
def set_is_ignored(v)
  @is_ignored = v == 'TRUE'
end #/ set_is_ignored

# Pour updater les valeurs +data+ dans la base de données
def update_in_db(data)
  Runner.itexte.db.update_text_item(data.merge!(id: id))
end #/ update_in_db

# @Return les valeurs pour la table text_items
# Ci-dessous, on ne peut pas utiliser collect avec compact pour supprimer les
# valeurs nil, car beaucoup de valeurs seraient supprimées dès qu'elles sont
# nulles, ce qui se produit souvent au moment du parsing (is_mot, offset, index
# etc. ne sont pas encore définis)
def db_values
  ary = []
  TextSQLite::DATA_TABLE_TEXT_ITEMS.collect do |dcol|
    next if dcol[:insert] === false
    getter = "get_#{dcol[:property]}".to_sym # p.e. #get_is_mot
    ary << self.send(self.respond_to?(getter) ? getter : dcol[:property_sym])
  end
  ary
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
  @f_length = nil
  @f_content  = nil
  @is_not_proximizabe   = nil
  @is_in_extrait = nil
  @prox_avant = nil
  @prox_avant_calculed  = nil
  @prox_apres = nil
  @prox_apres_calculed  = nil
  @has_canon_exclu = nil
end #/ reset


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
  "Content:'#{content}'/Offset:#{offset.inspect}/Length:#{length.inspect}/Index:#{index.inspect}"
end #/ to_s

def length
  @length ||= content.length
end #/ length

def downcase
  @downcase ||= content.downcase
end #/ downcase

def main_type
  @main_type ||= begin
    # SPARADRAP - quand le type est nil, chercher dans la base lemmas pour
    # trouver le mot. Dans tous les cas
    if type.nil?
      if canon.nil?
        dcanon = get_data_canon
        if not dcanon.nil?
          @canon  = dcanon['Canon']
          @type   = dcanon['Type']
        else
          # CANON INTROUVABLE, IL FAUT DONNER DES VALEURS ALTERNATIVES
          @canon  = LEMMA_UNKNOWN
          @type   = 'TYPE_INCONNU'.freeze
        end
        update_in_db(canon: @canon, type: @type)
      end
    end
    type.split(DEUX_POINTS).first
  rescue Exception => e
    erreur("PROBLÈME AVEC #{self.inspect} : #{e.message}")
    erreur(e)
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
  @f_content ||= content.ljust(f_length)
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
  if no_proximites?
    SPACE * f_length
  else
    s = []
    s << (prox_avant.nil? ? '' : prox_avant.mot_avant.index_in_page)
    s << '|'
    s << (prox_apres.nil? ? '' : prox_apres.mot_apres.index_in_page)

    # log("Index(s) de proximité de ##{id} : #{s.inspect}")

    if s.join(EMPTY_STRING).length < f_length
      s[0] = s[0].ljust((f_length / 2) - 1)
      s[2] = s[2].rjust(f_length - s[0..1].join('').length)
    end

    s.join(EMPTY_STRING)
  end
end #/ f_proximities

# Calcule les longueurs du text-item dans l'extrait +iextrait+
def calcule_longueurs(iextrait)
  if non_mot?
    @f_length = content.length
  else
    candidats_longueurs = []
    # La longueur du text-item est le premier candidat pour la longueur
    candidats_longueurs << length
    # Longueur occupée par l'index du mot
    candidats_longueurs << index_in_extrait.to_s.length
    # S'il y a des proximités, on définit la longueur au plus long des trois
    candidats_longueurs << proximites_length if has_proximites?
    @f_length = candidats_longueurs.max
  end
end #/ calcule_longueurs

# Calcule la longeur qu'occuperait l'indication des proximités par rapport
# à l'extrait courant.
# L'indication des proximités se fait avec l'index relatif du mot à l'écran
#
def proximites_length
  dist = []
  dist << (prox_avant.nil? ? 0 : (prox_avant.mot_avant.index_in_page).length)
  dist << (prox_apres.nil? ? 0 : (prox_apres.mot_apres.index_in_page).length)

  dist.inject(:+) + 1 # +1 pour la barre (dans tous les cas)
end #/ proximites_length

# Retourne true si le text-item se trouve dans l'extrait affiché
def in_extrait?
  @is_in_extrait ||= begin
    raise("index ne devrait pas être nil") if index.nil?
    # @is_in_extrait = index >= ProxPage.current_page.from && index <= ProxPage.current_page.to
    @is_in_extrait = index >= Runner.iextrait.from_item && index <= Runner.iextrait.to_item
    @is_in_extrait = @is_in_extrait ? :true : :false
  end
  @is_in_extrait == :true
end #/ in_extrait?

# Retourne true si le text-item peut être étudié au niveau de ses proximités
def proximizable?
  @is_not_proximizabe ||= begin
    # Note : il ne faut pas ajouter la condition `canon == LEMMA_UNKNOWN` car
    # dans ce cas, on peut comparer le contenu lui-même.
    if non_mot? || ignored? || length < 4 || icanon.nil? || is_exclu? || main_type == 'PRO' || main_type == 'DET'
      :false
    else
      :true
    end
  end
  @is_not_proximizabe === :true
end #/ proximizable?

def is_exclu?
  @has_canon_exclu ||= begin
    ( MOTS_SANS_PROXIMITES.key?(downcase) || Runner.itexte.liste_mots_sans_prox.key?(canon) )? :true : :false
  end
  @has_canon_exclu == :true
end #/ is_exclu?

def has_unknown_canon?
  @canon_is_unknown = canon == LEMMA_UNKNOWN if @canon_is_unknown.nil?
  @canon_is_unknown
end #/ has_unknown_canon?
def new_paragraphe?
  content == RC
end #/ new_paragraphe?

def space?
  @is_space ||= (non_mot? && content == SPACE) ? :true : :false
  @is_space === :true
end #/ space

def no_proximites?
  not(proximizable?) || (prox_avant.nil? && prox_apres.nil?)
end #/ no_proximites?
def has_proximites?
  # log("has_proximites? = #{not(no_proximites?).inspect}")
  not(no_proximites?)
end #/ has_proximites?

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

# Définit et retourne l'instance Proximity d'une proximité avec un mot
# avant, si elle existe. Renvoie nil otherwise.
def prox_avant
  @prox_avant_calculed || begin
    # log("-> prox_avant après @prox_avant_calculed")
    if not proximizable?
      # log("pas proximizable donc @prox_avant = nil") if downcase == 'autre'
      @prox_avant = nil
    else
      iext = Runner.iextrait
      # log("*** Recherche proximité avant de #{cio} ***")
      # log("Offsets du canon #{icanon.canon.inspect} : #{icanon.offsets.inspect}")

      # Maintenant qu'on travaille seulement avec l'extrait, il suffit de
      # chercher le mot, dans les mots avant l'index du mot, qui ait le même
      # canon et qui soit à la bonne distance.
      # Pour ce faire, on prend les titems avant l'extrait ainsi que les mots
      # de l'extrait avant le mot étudié.
      # Mais attention, car la méthode peut être appelée hors extrait, lorsqu'on
      # fait un rapport ou qu'on débuggue un mot. Dans ce cas-là, la procédure
      # est tout autre.
      if in_extrait?
        liste_seek =  iext.extrait_pre_items.dup
        liste_seek += iext.extrait_titems[0...index_in_extrait] if index_in_extrait > 0
      else
        liste_seek = Runner.itexte.get_titems(from_offset: offset - Runner.itexte.distance_minimale_commune, to_offset: offset - 1)
      end

      @prox_avant = nil
      # Pop(per) dans la liste fouillé, c'est prendre d'abord les mots les plus
      # proches pour aller ensuite vers les mots les plus éloignés.
      while titem_avant = liste_seek.pop
        next if not titem_avant.proximizable?
        # Quand le canon du mot est inconnu, on compare les mots entre eux,
        # minusculisés
        next if (has_unknown_canon? || titem_avant.has_unknown_canon?) && titem_avant.downcase != downcase
        next if titem_avant.canon != canon
        distance = offset - titem_avant.offset
        break if distance > Canon[canon].distance_minimale
        # Si on passe ici, c'est qu'un item proche a été trouvé
        # log("Proximity avant trouvée pour #{self.cio} avec : #{titem_avant.cio}")
        @prox_avant = Proximite.new(avant:titem_avant, apres:self, distance:distance)
        titem_avant.prox_apres = @prox_avant
        # Puisqu'on lisait la liste à l'envers (pop), le premier titem trouvé
        # est forcément le plus proche. On peut breaker
        break
      end
    end
    @prox_avant_calculed = true
  end
  @prox_avant
end #/ prox_avant
def prox_avant=(prox)
  @prox_avant = prox
  @prox_avant_calculed = true
end

def prox_apres
   @prox_apres_calculed || begin
    if not proximizable?
      @prox_apres = nil
    else
      # Raccourci
      iextr = Runner.iextrait

      # La liste de tous les text-items dans lesquels il va falloir chercher
      # Le cas est différent suivant que le mot se trouve dans l'extrait ou
      # en dehors.
      # NOTE : si la distinction entre dans/hors extrait est trop consommatrice,
      # on pourrait isoler les deux procédures et les appeler explicitement au
      # besoin.
      if in_extrait?
        liste_seek = iextr.extrait_titems[index_in_extrait+1..-1]
        liste_seek += iextr.extrait_post_items
      else
        liste_seek = Runner.itexte.get_titems(from_offset:offset+1, to_offset:offset + Runner.itexte.distance_minimale_commune)
      end

      liste_seek.reverse! # pour pouvoir pop(er) au lieu de shift(er)

      @prox_apres = nil
      while titem_apres = liste_seek.pop
        next if not titem_apres.proximizable?
        # Quand le canon du mot est inconnu, on compare les mots entre eux,
        # minusculisés
        next if (has_unknown_canon? || titem_apres.has_unknown_canon?) && titem_apres.downcase != downcase
        next if titem_apres.canon != canon
        # On passe ici si le mot est proximizable et si le mot après possède
        # le même canon OU est égal en minuscule.
        distance = titem_apres.offset - offset
        break if distance > Canon[canon].distance_minimale
        # Si on passe ici c'est qu'un mot proche a été trouvé
        # log("Proximity après trouvée pour #{self.cio} : #{titem_apres.cio}")
        @prox_apres = Proximite.new(avant:self, apres:titem_apres, distance:distance)
        titem_apres.prox_avant = @prox_apres
        break   # on s'arrête là, puisque le prochain mot serait forcément plus
                # loin
      end
    end
    @prox_apres_calculed = true
  end
  @prox_apres
end #/ prox_apres

def prox_apres=(prox)
  @prox_apres = prox
  @prox_apres_calculed = true
end


# @Return l'index {String} dans la page
# Cette méthode est utilisée uniquement pour l'affichage de la page courante,
# pour afficher les proximités.
# Il y a trois possibilités et 3 traitements possibles :
#   - le mot se trouve avant la page affichée => il porte la marque "-" et
#     l'index dans la page précédente.
#   - le mot se trouve dans la page affichée => simple, juste l'index
#   - le mot se trouve dans la page après celle affichée => il porte la marque
#     "+" et l'index dans la page suivante
def index_in_page
  curpage = ProxPage.current_numero_page
  # log("* Recherche index-in-page de #{cio}")
  # log("  index in extrait: #{index_in_extrait.inspect}")
  # log("Numéro page courante : #{curpage.inspect}")
  # log("Runner.iextrait.to_item: #{Runner.iextrait.to_item.inspect}")
  # log("Runner.iextrait.from_item: #{Runner.iextrait.from_item.inspect}")
  if in_current_page?
    # log("Le mot #{cio} est dans la page courante")
    index_in_extrait.to_s
  elsif in_prev_page?
    # log("Le mot #{cio} est dans la page précédente")
    if curpage.nil?
      # Quand l'extrait n'est pas une page (i.e. il a été affiché à partir
      # d'un `:show xxxx`), on indique simplement la différence d'indice entre
      # le mot courant et sa proximité
      "#{index_in_extrait.inspect}".freeze # le "-" sera ajouté
    else
      # Une page est affichée, on peut trouver l'indice du mot sur la
      # page précédente
      prev_page = ProxPage.pages[curpage - 1]
      index_rel = index - prev_page.from
      "-#{index_rel}".freeze
    end
  elsif in_next_page?
    # log("Le mot #{cio} est dans la page suivante")
    if curpage.nil?
      "+#{index_in_extrait}".freeze
    else
      next_page = ProxPage.pages[curpage + 1]
      # log("next page : #{next_page.inspect}")
      index_rel = index - next_page.from
      # log("=> index_rel +#{index_rel}")
      "+#{index_rel}".freeze
    end
  end
end #/ index_in_page

private

  def in_current_page?
    not(in_prev_page?) && not(in_next_page?)
  end #/ in_current_page?
  def in_prev_page?
    if index_in_extrait.nil?
      index >= Runner.iextrait.extrait_pre_items.first.index &&
      index < Runner.iextrait.extrait_titems.first.index
    else
      index_in_extrait < 0
    end
  end #/ in_prev_page?
  def in_next_page?
    index > Runner.iextrait.to_item && index <= Runner.iextrait.extrait_post_items.last.index
  end #/ in_next_page?

end #/TexteItem
