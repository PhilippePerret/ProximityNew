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
TEXTE_COLS_WIDTH      = 100
class << self

# Hash contenant les instances des pages, calculées au chargement
# du texte ou après son analyse.
attr_reader :pages

# Index de la page courante
# Il est défini à l'instanciation de l'extrait courant. Il est mis à nil
# lorsque ce n'est pas une page qui est affiché.
attr_accessor :current_numero_page

# Page courant (instance ProxPage)
def current_page ; pages[current_numero_page] end #/ current_page

# Cette méthode calcule les pages au chargement du texte
# Pour le moment, elle est à l'essai pour savoir si elle ne prendra pas
# trop de temps au chargement.
def calcule_pages(itexte)
  itexte ||= Runner.itexte
  log("Calcul des pages. Merci de patienter…", true)
  start_time = Time.now.to_f
  db_result = itexte.db.execute(GET_PAGES_USEFULL_INFOS_DB)
  # log("db_result pour le calcul des pages : #{db_result.inspect}") # ATTENTION : GROS SI GROS FICHIER
  # Les pages qu'on va rassembler. En clé, il y aura l'indice de la
  # page (1-start) et en valeur une instance ProxPage qui définira notamment
  # @from et @to, les index de départ et d'arrivée
  @pages = {}
  @current_long = 0
  @current_line = 1
  @current_page = 1
  # L'index courant dans la page. Il va permettre de savoir s'il faut ajouter
  # ou non des espaces pour la longueur.
  @current_index_in_page = 0

  @from_index = 0

  # On boucle sur chaque text-item pour définir le premier et le dernier
  # de chaque page en fonction des longueurs.
  db_result.each do |row|

    # Le text-item courant
    index, longueur, index_charriot, is_mot = row
    has_charriot = index_charriot > 0
    is_mot = is_mot == 'TRUE' ? true : false
    # Pour les mots, si leur longueur est inférieure à la longueur que va
    # prendre l'index courant dans la page, on doit ajouter la différence
    # pour connaitre la longueur à prendre en compte. Ici, on aura seulement
    # les proximités qui pourront allonger la longueur.
    # NOTE Si on voit vraiment que les proximités ajoutent beaucoup, il faut
    # avoir la possibilité d'ajouter 1 à chaque mot.
    index_len = @current_index_in_page.to_s.length
    if is_mot && longueur < index_len
      longueur += (index_len - longueur) if is_mot
    end

    # Si c'est un retour chariot, on passe à la ligne suivante et peut-être
    # à la page suivante.
    if has_charriot
      create_new_line(@from_index, index)
      # On peut tout de suite passer au text-item suivant.
      next
    end

    # # Debug only
    # if @current_page == 1
    #   log("[idx:#{index}] Longueur courante : #{@current_long} + longueur #{longueur} > #{max_line_length}")
    # end

    # Si on dépasse la longueur max de la ligne en ajoutant cette longueur
    # à la longueur courante alors il faut passer à la ligne suivante
    # Si on passe à la page suivante, on crée une nouvelle page.
    if @current_long + longueur > max_line_length
      create_new_line(@from_index, index - 1)
    end

    # On ajoute la longueur du text-item courant à la longueur de la
    # ligne.
    @current_long += longueur
    @current_index_in_page += 1
    # Pour se souvenir du dernier index traité, pour la dernière page qui
    # sera créé en sortie de boucle
    @last_index = index

  end #/ fin de boucle sur chaque mot (il peut y en avoir des dizaines de milliers)

  # On enregistre la dernière page, mais seulement si elle existe vraiment
  if @from_index < @last_index
    create_new_page(numero:@current_page, from:@from_index, to:@last_index, lines_count:@current_line)
  end

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
# par l'index +from_index+
def last_item_page_from_index(itexte, from_item)
  to_item = nil
  log("Recherche du dernier index…", true)
  start_time = Time.now.to_i
  # On relève une quantité suffisante d'item dans la base
  # old_results_as_hash = itexte.db.results_as_hash
  itexte.db.results_as_hash = false
  db_result = itexte.db.execute(REQUEST_GET_TITEMS_INFOS_FROM_FOR, from_item, from_item + 300)
  # itexte.db.results_as_hash = old_results_as_hash
  @current_long = 0
  @current_line = 1
  @current_page = 1 # juste pour savoir si on va passer à la page suivante, ici
  # L'index courant dans la page. Il va permettre de savoir s'il faut ajouter
  # ou non des espaces au mot pour la longueur.
  @current_index_in_page = 0
  db_result.each do |row|
    # Le text-item courant
    index, longueur, index_charriot, is_mot = row
    # log("row: #{row.inspect}")

    # Pour qu'il y en ai toujours un défini, même si on n'en a pas assez
    # pour aller au bout de la page
    to_item = index

    has_charriot = index_charriot > 0
    is_mot = is_mot == 'TRUE' ? true : false
    # Pour les mots, si leur longueur est inférieure à la longueur que va
    # prendre l'index courant dans la page, on doit ajouter la différence
    # pour connaitre la longueur à prendre en compte. Ici, on aura seulement
    # les proximités qui pourront allonger la longueur.
    index_len = @current_index_in_page.to_s.length
    if is_mot && longueur < index_len
      longueur += (index_len - longueur) if is_mot
    end

    # Si c'est un retour chariot, on passe à la ligne suivante et peut-être
    # à la page suivante.
    if has_charriot
      create_new_line(@from_index, index, {noop: true})
      if @current_page == 2
        # On est passé à la page suivante, on peut prendre le dernier index
        # et le retourner.
        to_item = index
        break
      end
      # On peut tout de suite passer au text-item suivant.
      next
    end

    # Si on dépasse la longueur max de la ligne en ajoutant cette longueur
    # à la longueur courante alors il faut passer à la ligne suivante
    # Si on passe à la page suivante, on crée une nouvelle page.
    if @current_long + longueur > max_line_length
      create_new_line(@from_index, index - 1, {noop: true})
      if @current_page == 2
        # On est passé à la page suivante, on peut prendre le dernier index
        # et le retourner.
        to_item = index - 1
        break
      end
    end

    # On ajoute la longueur du text-item courant à la longueur de la
    # ligne.
    @current_long += longueur
    @current_index_in_page += 1

  end #/ fin de boucle sur chaque mot (il peut y en avoir des dizaines de milliers)

  end_time = Time.now.to_f
  msg_dbg = "Dernier index trouvé en #{end_time - start_time} secs.".freeze
  log(msg_dbg, true)

  to_item
end #/ last_item_page_from_index

# Méthode qui reçoit un index quelconque et retourne l'instance de la
# page concernée.
def page_from_index_mot(index)
  found_page = nil
  log("Recherche de la page courante…".freeze, true)

  if pages.nil?
    log("ProxPage.pages est nil. Il faudra voir pourquoi.", true)
    return nil
  end
  # log("pages: #{pages.inspect}")

  pages.each do |numero, page|
    # log("#{page.from} < #{index} > #{page.to}")
    if page.from <= index && page.to >= index
      # log("Page trouvée : #{page.numero} !".freeze, true)
      found_page = page
      break
    end
  end

  found_page
end #/ page_from_index_mot

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
  @max_lines_per_page ||= begin
    ((CWindow.hauteur_texte) / 3)  - 1
  end
end #/ max_lines_per_page

# @Return le dernier numéro de page du texte courant
def last_numero_page
  @last_numero_page ||= pages.values.last.numero
end #/ last_numero_page

private
  # @Params
  #   +to_index   Il faut le préciser en argument car quelquefois c'est le
  #               tout dernier index dans la boucle, parfois c'est le précédent.
  def create_new_line(from_idx, to_idx, options = nil)
    options ||= {}
    @current_line += 1
    @current_long = 0
    # Si la ligne suivante passe à la page suivante, on doit initier une
    # nouvelle page
    if @current_line >= max_lines_per_page
      numero = @current_page.dup
      # options[:noop] est vrai quand on cherche simplement le dernier index
      # d'une page virtuelle/temporaire.
      unless options[:noop]
        create_new_page(numero:numero, from: from_idx, to:to_idx, lines_count:@current_line)
        # log("Enregistrement de @current_page #{numero.inspect} : #{{numero:numero, from:from_idx, to:to_idx}.inspect}")
      end
      @current_page   += 1
      @current_line   = 1
      @from_index     = to_idx + 1
      @current_index_in_page = 0
    end
  end #/ create_new_ligne

  def create_new_page(params)
    # debug("[ProxPage::create_new_page] Nouvelle page créée : #{params.inspect}")
    @pages.merge!(params[:numero] => ProxPage.new(params))
  end #/ create_new_page

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :from, :to, :numero, :lines_count
def initialize(data)
  @from   = data[:from]
  @to     = data[:to]
  @numero = data[:numero]
  @lines_count = data[:lines_count]
end #/ initialize



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
# Requête qui permet de relever les informations utiles pour calculer les
# pages dans la base de données
GET_PAGES_USEFULL_INFOS_DB = <<-SQL.freeze.strip
SELECT
  Idx,
  LENGTH(Content),
  INSTR(Content, #{RC.inspect}),
  IsMot
FROM text_items
ORDER BY Offset ASC
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
