# encoding: UTF-8
=begin
  Class ProxPage
  ---------------
  La classe ProxPage permet de gérer les pages affichées à l'écran.
  Ces pages sont définies par un :
    :from       l'index absolu du mot de départ
    :to         l'index absolu du mot de fin
  Elles sont enregistrées au fur et à mesure de la consultation du
  texte.

=end
class ProxPage
# La largeur maximale pour la ligne, qu'on ne peut pas dépasser même
# si l'écran est plus grand.
TEXTE_COLS_WIDTH = 100
# Le nombre d'espaces laissés à droite pour la marge
RIGHT_MARGIN = 4
# Idem à gauche
LEFT_MARGIN = 4

# ---------------------------------------------------------------------
#
#   CLASSE
#
# ---------------------------------------------------------------------
class << self

# Array contenant les instances des pages, calculées au chargement
# du texte ou après son analyse.
# Pour récupérer une page :
#     ProxPage.page(numero)
attr_reader :pages

# Array consignant les premiers ids de toutes les pages
# Cette liste permet de savoir si un text-item supprimé était le
# premier titem d'une page ou si un élément inséré devient le premier
# titem d'une page (dans lequel cas il faut recalculer les pages)
attr_reader :pages_by_titem_id

# Index de la page courante
# Il est défini à l'instanciation de l'extrait courant. Il est mis à nil
# lorsque ce n'est pas une page qui est affiché.
attr_accessor :current_numero_page

# @Return true si l'identifiant +id+ est le premier identifiant d'une
# page.
def is_first_id_page?(id)
  pages_by_titem_id.key?(id)
end #/ is_first_id_page?

# Page courante (instance {ProxPage})
def current_page ; page(current_numero_page) end
def current_page=(v)
  self.current_numero_page = v.numero
  # log("Numéro page courante : #{current_numero_page.inspect}")
  if current_page.nil?
    raise("Le numéro #{current_numero_page} ne correspond à aucun page !")
  end
end

# @Return l'instance ProxPage de la page de numéro +numero+
def page(numero)
  pages[numero - 1]
end #/ page

# Ajoute la page virtuelle +ipage+ à la liste des pages et à la table
# qui consigne les pages par identifiant du premier text-item
def add_page(ipage)
  # log("Ajout à @pages de la page #{ipage.inspect}")
  @pages << ipage
  @pages_by_titem_id ||= {}
  @pages_by_titem_id.merge!(ipage.first_titem.id => ipage)
end #/ add_page

# Cette méthode calcule les pages au chargement du texte
# Elle calcule ces pages en fonction de la taille de l'écran.
# C'est elle qui renseigne la donnée ProxPage.pages qui permettra de
# retrouver les index de toutes les pages.
def calcule_pages(itexte)
  itexte ||= Runner.itexte
  log("Calcul des pages. Merci de patienter…", true)

  # Pour savoir combien ça prendre de temps
  start_time = Time.now.to_f

  # On relève les informations de tous les text-items mais seulement celles
  # qui servent pour le calcul des pages, c'est-à-dire l'index, l'offset et
  # la longueur du mot. Et également pour savoir si c'est un mot ou un non-mot.
  all_mots_for_pages = itexte.db.execute(GET_PAGES_USEFULL_INFOS_DB)
  # log("db_result pour le calcul des pages : #{db_result.inspect}") # ATTENTION : GROS SI GROS FICHIER

  # Toutes les pages du texte.
  # Note : le premier élément étant NIL, on peut récupérer une page par
  # son numéro avec @pages[numero] ou ProxPage.page(numero)
  @pages = []

  # La longueur de ligne courant, pour savoir si on doit passer à la ligne
  @current_line_length = 0
  # L'instance ProxPage de la page courante
  @current_page = nil
  # L'index courant du text-item dans la page courante. Il va permettre de
  # savoir s'il faut ajouter ou non des espaces pour la longueur quand l'index
  # devient grand. Par exemple, si le mot est "à" est que l'index est 265, le
  # mot n'aura pas une longueur de 1 (pour "à") mais une longueur de 3 (pour
  # "265").
  @current_index_in_extrait = -1 # -1 pour commencer à 0

  # Bizarre, j'ai dû rajouter ça tout à coup
  @lines_count = 0

  # On transforme les données relevées en instance TextItemPage qui seront
  # plus faciles à manipuler
  all_titems = all_mots_for_pages.collect do |row|
    # Les infos du text-item courant de +row+
    TextItemPage.new(*row)
  end

  # On retourne la liste des text-items pour pouvoir pop(er) au lieu
  # de shift(er)
  all_titems.reverse!

  # L'index du text-item dans la page. Il sera réinitialiser à chaque
  # nouvelle page et permet de compter plus justement la longueur que
  # prendra le text-item
  @index_in_page = -1 # -1 pour commencer à 0

  # On boucle sur chaque text-item pour définir le premier et le dernier
  # de chaque page en fonction des longueurs.
  # On a besoin de l'index (+idx+) pour récupérer le text-item suivant et
  # voir si c'est une ponctuation ou une fin de phrase.
  while titem = all_titems.pop

    # Pour le message de log
    msg_log = []

    titem.index_in_page = ( @index_in_page += 1 )

    msg_log << "#{RC*2}ÉTUDE DU MOT ““#{titem.content}””"

    # log("titem #{titem.index} length: #{titem.length} / @current_line_length = #{@current_line_length.inspect}")

    # Faut-il créer une nouvelle page ?
    # Il le faut lorsque :
    #   - il n'y a aucune page (comme au tout début de la boucle)
    #   - la ligne courante est supérieure au nombre de lignes possibles
    #     dans une page.
    # Dans ces deux cas, on crée une nouvelle page qui commencera à
    # l'identifiant du mot courant
    if @current_page.nil? || @current_page.lines_count == max_lines_per_page
      # log("[Nouvelle page] @current_line_length = #{@current_line_length.inspect} / @current_page (#{@current_page&.numero.inspect}).lines_count (#{@current_page&.lines_count.inspect}) > max_lines_per_page (#{max_lines_per_page.inspect}) ? #{(@current_page&.lines_count.to_i > max_lines_per_page).inspect}")
      @current_page = ProxPage.new(first_titem:titem)

      # On ré-initialise les valeurs
      @index_in_page = -1 # pour commencer à 0
      @current_line_length = 0
    end

    # # Debug - Etat des lieux
    # #
    # if titem.index < 700 # true # false pour ne pas debugger
    #   msg = "#{RC}-- TITEM index:#{titem.index} - longueur:#{titem.length} - is_mot:#{titem.mot?.inspect}"
    #   msg << "#{RC}   avec : @current_index_in_extrait:#{@current_index_in_extrait.inspect} (@from_index:#{@from_index.inspect}) @current_long:#{@current_long.inspect} @current_line:#{@current_line.inspect} @current_page:#{@current_page.inspect}"
    #   log(msg)
    # end

    # On prend l'item suivant pour savoir si c'est une ponctuation. Si c'est
    # une ponctuation, il faut l'ajouter à l'item courant
    next_titem = all_titems[-1]
    if next_titem.ponctuation?
      msg_log << "Le titem suivant (““#{next_titem.content}””) est une ponctuation".freeze
      all_titems.pop
    end

    # On peut calculer la longueur que prendra ce text-item (avec peut-être
    # la ponctuation qui lui sera collée)
    len_for_titem = titem.length.dup
    len_for_titem += next_titem.length if next_titem && next_titem.ponctuation?
    msg_log << "  - longueur (#{next_titem.ponctuation? ? 'avec' : 'sans'} ponctuation) : #{len_for_titem}".freeze

    next_cursor_offset = @current_line_length + len_for_titem
    msg_log << "  - next_cursor_offset se trouverait à #{next_cursor_offset}".freeze

    # Si on dépasse la longueur max de la ligne en ajoutant cette longueur
    # à la longueur courante alors il faut passer à la ligne suivante
    # log("@current_line_length (#{@current_line_length.inspect}) + titem.length (#{titem.length.inspect}) >= max_line_length (#{max_line_length.inspect}) donne #{(@current_line_length + titem.length >= max_line_length).inspect}")
    if  next_cursor_offset >= max_text_length
      msg_log << "   Ce next_cursor_offset est >= à la longueur de texte maximale (#{max_text_length})".freeze

      # On ajoute une ligne à la page courante
      # log("Avant ajout ligne : @current_line_length = #{@current_line_length.inspect} / @current_page (#{@current_page&.numero.inspect}).lines_count (#{@current_page.lines_count.inspect}) > max_lines_per_page (#{max_lines_per_page.inspect}) ? #{(@current_page.lines_count > max_lines_per_page).inspect}")
      @current_page.add_line
      msg_log << "   Ligne ajoutée à la page (#{@current_page.lines_count})".freeze

      # La longueur de la nouvelle ligne est ré-initialisée.
      @current_line_length = 0

    else

      # Le cas normal où il ne faut qu'ajouter la longueur du text-item
      # à la longueur de la ligne courante.

    end

    # Dans tous les cas, on ajoute la longueur du text-item et peut-être
    # la longueur du text-item suivant
    @current_line_length += len_for_titem

    # Pour connaitre le dernier index du texte (utile pour connaitre le
    # dernier index de la page quand c'est la toute dernière.)
    # Réglé en rafale mais de toute façon il y aura une victime…
    Runner.itexte.last_index = titem.index

    log(msg_log.join(RC) + RC*2)

  end
  #/ fin de boucle sur chaque mot (il peut y en avoir des dizaines de milliers)

  log("Dernier index du texte (Runner.itexte.last_index) : #{Runner.itexte.last_index.inspect}")

  end_time = Time.now.to_f
  # debug(rows_debug.join(RC))
  debug(msg_dbg = "Pages calculées en #{end_time - start_time} secs.".freeze)
  log(msg_dbg, true)

  # Pour débugger les pages obtenues
  # debug(pages.inspect)

rescue Exception => e
  erreur(e)
end #/ calcule_pages


# @Return l'index du dernier item d'une page temporaire qui doit commencer
# par l'index +from_index+ dans le texte +itexte+ (toujours le texte courant)
# Fonctionnement :
#   - on trouve la page correspondant à +from_index+
#   - on cherche l'identifiant du titem de la page suivante (si elle existe)
#   - on prend l'index de ce titem (s'il existe)
def last_item_page_from_index(itexte, from_index)
  log("Recherche du dernier index…", true)
  pag = get_page_from_index(from_index)
  pag.last_index
end #/ last_item_page_from_index


# Méthode qui reçoit un index quelconque et retourne l'instance de la
# page concernée.
# C'est la méthode, par exemple, qui est appelé à l'ouverture, pour afficher
# la dernière page corrigée en fournissant le dernier index enregistré (qui
# correspond à l'index du premier text-item de la dernière page affichée)
def page_from_index_mot(index)
  found_page = nil
  log("Recherche de la page courante…".freeze, true)

  pages.each do |ipage|
    # log("#{page.from} < #{index} > #{page.to}")
    if index >= ipage.first_index && index <= ipage.last_index
      log("Page trouvée : #{ipage.numero} !".freeze, true)
      found_page = ipage
      break
    end
  end

  found_page
end #/ page_from_index_mot

# @Return {Integer} la longueur maximale du texte, hors marges. C'est-à-dire
# la longueur que peut vraiment avoir le texte dans l'affichage.
# Le +4 permet un "tampon" pour mettre les proximités s'il y en a
def max_text_length
  @max_text_length ||= max_line_length - ( RIGHT_MARGIN + LEFT_MARGIN + 4 )
end #/ max_text_length

# @Return la longueur maximale horizontale pour une ligne de texte.
# Elle est calculée en fonction de la largeur de l'écran et d'un
# nombre maximum à ne jamais dépasser (TEXTE_COLS_WIDTH)
def max_line_length
  @max_line_length ||= begin
    mll = Curses.cols - 6
    mll = TEXTE_COLS_WIDTH if mll > TEXTE_COLS_WIDTH
    mll
  end
end #/ max_line_length

# @Return le nombre de lignes maximum dans une page.
# Note : une ligne de texte occupe trois lignes :
#   ligne des index
#   ligne du texte
#   ligne des proximités
# C'est la raison pour laquelle il faut diviser par 3
def max_lines_per_page
  10
  # @max_lines_per_page ||= begin
  #   ((CWindow.hauteur_texte) / 3) - 4
  # end
end #/ max_lines_per_page

# @Return le dernier numéro de page du texte courant
def last_numero_page
  @last_numero_page ||= pages.last.numero
end #/ last_numero_page

# @Return le numéro pour une nouvelle page
def next_numero
  @current_page_numero ||= 0
  @current_page_numero += 1
end #/ next_numero

end # /<< self






# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------



attr_accessor :numero, :lines_count, :first_titem
def initialize(data)
  data.each { |k, v| instance_variable_set("@#{k}", v) }
  self.numero = self.class.next_numero
  self.class.add_page(self)
end #/ initialize

# @Return les text-items de la page
# Noter qu'ici ces text-items sont complets, avec toutes leurs données,
# contrairement aux text-items qui sont utilisés pour le calcul des pages
def text_items
  @text_items ||= begin
    # Pour pouvoir récupérer les données sous forme de Hash.
    # Attention :
    #   * les clés sont des strings
    #   * les noms de colonnes sont avec capitales ("Offset", "Content", etc.)
    Runner.itexte.db.results_as_hash = true
    request = "SELECT * FROM text_items WHERE Idx >= ? AND Idx <= ? ORDER BY Idx ASC".freeze
    Runner.itexte.db.execute(request, first_index, last_index).collect.with_index do |hrow, idx|
      TexteItem.instantiate(hrow, idx)
    end
  end
end #/ text_items

def first_index
  @from ||= first_titem.index
end #/ from
alias :from_index :first_index
alias :from :first_index

# @Return le dernier index de la page (même pour la dernière)
def last_index
  @last_index ||= begin
    # log("pages:#{ProxPage.pages.inspect}")
    # log("next page : #{self.next.inspect}")
    # log("Premier index de page suivante : #{self.next&.first_index}")
    self.next.nil? ? Runner.itexte.last_index : self.next.first_index - 1
  end
end #/ last_index
alias :to_index :last_index

def first_titem_id
  @first_titem_id ||= first_titem.id
end #/ first_titem_id

# @Return un String pour le débuggage de la page
def debug
  "#{numero.to_s.ljust(4)}#{first_titem_id.to_s.ljust(7)}#{from.to_s.ljust(8)}#{@to.to_s.ljust(8)}".freeze
end #/ debug

# @Return l'instance ProxPage de la page suivante ou nil si elle n'existe pas
def next
  @next ||= self.class.page(numero + 1) # nil si dernière
end #/ next


# @Return TRUE si c'est la dernière page
def last?
  @is_last_page ||= (self.pages.last.numero == numero ? :true : :false)
  @is_last_page = true
end #/ last?

# Retourne le nombre de lignes de la page (calculé au cours du calcul des
# pages)
def lines_count
  @lines_count ||= 0
end #/ lines_count

def add_line
  @lines_count ||= 0
  @lines_count += 1
end #/ add_line




# La vue SQLite qui va permettre de calculer vite les pages
# NOTE Je n'arrive pas à la faire fonctionner (JE PENSE QUE C'EST À CAUSE
# DE L'OUBLI DU POINT-VIRGULE À LA FIN - RAJOUTÉ)
SQLITE_CREATE_VIEW_PAGE = <<-SQL.freeze.strip
-- DROP VIEW prox_pages -- pour forcer à chaque fois au début
CREATE VIEW IF NOT EXISTS prox_pages (
  TitemIndex,
  Length,
  HasReturn
)
AS
  SELECT
    Idx,
    LENGTH(Content),
    INSTR(Content, "\n")
  FROM
    text_items
  ORDER BY
    Offset ASC
  ;
SQL
REQUEST_GET_TITEMS_INFOS_FROM_FOR = <<-SQL.freeze.strip
SELECT
  Idx,
  LENGTH(Content),
  INSTR(Content, #{RC.inspect}),
  IsMot
FROM text_items
WHERE Idx >= ? AND Idx < ?
ORDER BY `Offset` ASC
;
SQL

end #/ProxPage

# ---------------------------------------------------------------------
#
#   STRUCTURE POUR LES TEXT-ITEMS UTILES AUX PAGES
#
# ---------------------------------------------------------------------

# Requête qui permet de relever les informations utiles pour calculer les
# pages dans la base de données
# Note : en version debug, j'ajoute le contenu du mot
GET_PAGES_USEFULL_INFOS_DB = <<-SQL.freeze.strip
SELECT
  Id,
  Idx,
  LENGTH(Content),
  INSTR(Content, "\n"),
  IsMot,
  SUBSTR(Content,1,1) AS FirstChar,
  Content
FROM text_items
ORDER BY Offset ASC
SQL
# Structure MotPage pour simplifier le travail avec l'établissement des
# pages en fonction de l'interface.
# La liste des arguments ci-dessous doit correspondre à la liste des
# arguments de la classe SELECT ci-dessus.
TextItemPage = Struct.new(:id, :index, :content_length, :offset_rc, :is_mot, :first_char, :content) do

  attr_accessor :index_in_page

  # Longueur effectif du text-item dans la page
  # -------------------------------------------
  # Pour les mots, si leur longueur est inférieure à la longueur que va
  # prendre l'index courant dans la page, on doit ajouter la différence
  # pour connaitre la longueur à prendre en compte. Ici, on aura seulement
  # les proximités qui pourront allonger la longueur.
  def length
    @length ||= begin
      if mot? && index_length > content_length
        index_length
      else
        content_length
      end
    end
  end #/ length

  def index_length
    @index_length ||= index_in_page.to_s.length
  end #/ index_length

  def mot?
    @is_a_mot ||= (is_mot == 'TRUE' ? :true : :false)
    @is_a_mot == :true
  end #/ mot?

  def ponctuation?
    not(mot?) && not(!!FIRST_SIGN_PHRASE[content[0]]) && ( has_point? || new_paragraph? )
  end #/ ponctuation?

  def new_paragraph?
    @has_charriot ||= (offset_rc > 0 ? :true : :false)
    @has_charriot == :true
  end #/ has_charriot?

  def has_point?
    @text_has_point ||= (content.match?(/[?!;.…:,]/) ? :true : :false)
    @text_has_point == :true
  end #/ has_point?

  # @Return TRUE si le text-item commence par signe pouvant commencer une
  # phrase
  def start_with_tiret_or_guil?
    !!FIRST_SIGN_PHRASE[first_char]
  end #/ start_with_tiret_or_guil?
end
