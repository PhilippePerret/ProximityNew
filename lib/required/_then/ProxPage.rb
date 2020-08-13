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

  Note problème
    Le problème, actuellement, c'est que ces pages sont calculées par
    rapport à l'écran courant. Donc, si on change la taille de l'écran,
    elles ne sont plus valables et elle risque même de poser des problèmes.
    Je ne vois pas encore comment résoudre ce problème sans savoir encore
    calculer une page en arrière.
    Si je savais calculer une page en arrière (donc en définissant le
    to_item et en trouvant le from_item), on pourrait recalculer les pages
    à chaque utilisation :
      - le last_index est enregistré chaque fois, on repart de lui à
        l'ouverture du texte
      - on construit la première page à partir de là
      - ensuite, si l'user va en avant, on calcule de la même manière la
        page suivante.
      - si l'user va en arrière, on calcule la page avant pareille.
    En fait, si je connaissais la formule pour construire une page, je pourrais
    en relevant simplement les index et les longueurs (ainsi que les
    retours chariots) savoir trouver la page :
      - SELECT `Index`, LENGTH(Content) AS Length, ... FROM text_items
=end
class ProxPage
# La largeur maximale pour la ligne, qu'on ne peut pas dépasser même
# si l'écran est plus grand.
TEXTE_COLS_WIDTH      = 100
# La vue SQLite qui va permettre de calculer vite les pages
# NOTE Je n'arrive pas à la faire fonctionner
SQLITE_CREATE_VIEW_PAGE = <<-SQL.freeze.strip
-- DROP VIEW prox_pages -- pour forcer à chaque fois au début
CREATE VIEW IF NOT EXISTS prox_pages (
  TitemIndex,
  Length,
  HasReturn
)
AS
  SELECT
    `Index`,
    LENGTH(Content),
    INSTR(Content, "\n")
  FROM
    text_items
  ORDER BY
    Offset ASC
SQL
# Requête qui permet de relever les informations utiles pour calculer les
# pages dans la base de données
GET_PAGES_USEFULL_INFOS_DB = <<-SQL.freeze.strip
SELECT
  `Index`,
  LENGTH(Content),
  INSTR(Content, #{RC.inspect}),
  IsMot
FROM text_items
ORDER BY Offset ASC
SQL
class << self

  # Hash contenant les instances des pages, calculées au chargement
  # du texte ou après son analyse.
  attr_reader :pages

  # Cette méthode calcule les pages au chargement du texte
  # Pour le moment, elle est à l'essai pour savoir si elle ne prendra pas
  # trop de temps au chargement.
  def calcule_pages(itexte)
    itexte ||= Runner.itexte
    log("Calcul des pages. Merci de patienter…", true)
    start_time = Time.now.to_f
    db_result = itexte.db.execute(GET_PAGES_USEFULL_INFOS_DB)
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

    end #/ fin de boucle sur chaque mot (il peut y en avoir des dizaines de milliers)

    end_time = Time.now.to_f
    # debug(rows_debug.join(RC))
    debug(msg_dbg = "Pages calculées en #{end_time - start_time} msecs.".freeze)
    log(msg_dbg, true)

    # Pour débugger les pages obtenues
    # debug(pages.inspect)

  end #/ calcule_pages


  # Méthode qui reçoit un index quelconque et retourne l'instance de la
  # page concernée.
  def page_from_index_mot(index)
    found_page = nil
    log("Recherche de la page courante…".freeze, true)
    pages.each do |numero, page|
      log("#{page.from} < #{index} > #{page.to}")
      if page.from <= index && page.to >= index
        log("Page trouvée : #{page.numero} !".freeze, true)
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

private
  # @Params
  #   +to_index   Il faut le préciser en argument car quelquefois c'est le
  #               tout dernier index dans la boucle, parfois c'est le précédent.
  def create_new_line(from_idx, to_idx)
    @current_line += 1
    @current_long = 0
    # Si la ligne suivante passe à la page suivante, on doit initier une
    # nouvelle page
    if @current_line >= max_lines_per_page
      numero = @current_page.dup
      # log("Enregistrement de @current_page #{numero.inspect} : #{{numero:numero, from:from_idx, to:to_idx}.inspect}")
      @pages.merge!(numero => ProxPage.new(numero:numero, from:from_idx, to:to_idx, lines_count:@current_line))
      @current_page   += 1
      @current_line   = 1
      @from_index     = to_idx + 1
      @current_index_in_page = 0
    end
  end #/ create_new_ligne

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
end #/ProxPage
