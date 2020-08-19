# encoding: UTF-8
require 'tempfile'
require_relative '../Page'

class ExtraitTexte
DEFAULT_NOMBRE_ITEMS  = 400 # c'est de toute façon le nombre de lignes qui importe

# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :itexte, :from_item
attr_accessor :to_item
# L'instance ProxPage de la page de l'extrait. Elle définit notamment l'index
# de départ et l'index de fin.
attr_reader :page

# L'extrait peut s'instancier de deux façons :
# a) avec le numéro de page (params[:numero_page])
# b) avec l'index du mot, avec trois possibilités :
#   b.1) On veut la page contenant ce mot (même s'il n'est pas au début)
#   b.2) On veut l'extrait qui commence par ce mot dont l'index est donné
#        relativement à la page courante.
#   b.3) On veut l'extrait qui commence par ce mot dont l'index donné est
#        absolu.
# Pour b), params[:from_index] est défini.
# On traite les trois cas suivant la valeur de params[:index_is] qui peut être
#   b.1 : :in_page
#   b.2 : :relatif
#   b.3 : :absolu
def initialize itexte, params
  # log("params: #{params.inspect}")
  @itexte = itexte
  if params[:numero_page]
    # Quand on fournit le numéro de page à voir
    ProxPage.current_numero_page = params[:numero_page]
    @page = ProxPage.current_page
    @from_item = @page.from_index
    @to_item = @page.last_index
  elsif params.key?(:from_index)
    ProxPage.current_page = ProxPage.page_from_index_mot(params[:from_index])
  elsif params.key?(:index)
    # Quand on fournit un index de text-item
    @page = nil
    @from_item = nil
    case params[:index_is]
    when :absolu
      @from_item = params[:index]
      ProxPage.current_numero_page = nil
    when :in_page
      ProxPage.current_page = ProxPage.page_from_index_mot(params[:index])
      @page = ProxPage.current_page
      @from_item  = @page.from_index
      @to_item    = @page.last_index
    end
  end
  # Pour forcer la relève
  @extrait_titems = nil
end #/ initialize

# Préparation des listes
def prepare
  prepare_listes
end #/ prepare


# Sortie de l'extrait
# --------------------
# La mise en forme est assez complexe puisqu'elle
# doit mettre les index des mots ainsi que leur distance de proximité lorsqu'il
# y a proximité.
# On fonctionne mot à mot en sachant qu'une ligne est en réalité
# trois lignes l'une sur l'autre :
#   - ligne des index (avec index du mot en gris)
#   - ligne des mots proprement dit
#   - ligne des distances

# Longueur en signes du texte qu'on peut afficher dans la fenêtre de
# texte. Ce nombre peut être élevé puisque c'est en fait le nombre de
# lignes occupées qui va décider du nombre de mots.
LENGTH_TEXT_IN_TEXT_WINDOW = 1500 # pour essai

# Les espaces pour former la marge gauche
# OBSOLÈTE avec la nouvelle formule en deux temps (calcul page - affichage page)
SPACES_LEFT_MARGIN = (SPACE * ProxPage::LEFT_MARGIN).freeze

def output
  log("-> ExtraitTexte#output")

  # Dans la nouvelle formule, on a déjà récolté les text-items dans la base
  # de données qui correspondent au panneau demandé (à la page ProxPage).
  # Voir la préparation des listes.

  # On nettoie la fenêtre
  CWindow.textWind.clear

  # *** Définitions préliminaires ***

  # La ligne de texte courante à l'écran, qui doit correspondre au nombre
  # de lignes établies. Noter qu'ici :
  #
  #       1 ligne de texte = 3 lignes d'écran
  #
  #   1. ligne des index
  #   2. ligne du texte (des text-items)
  #   3. ligne des proximités (qu'il y en ait ou non)
  #
  current_line = 0

  # On écrit une ligne vierge au-dessus pour décoller du bord haut
  write_blank_line(0, 1)

  # On décale toujours d'une espace pour la lisibilité
  write_indentation(current_line)

  # +cursor_offset+ conserve la valeur x du décalage horizontal courant
  # Comme on a déjà indenté la ligne, on part à la valeur de la
  # marge gauche. NON. Maintenant, on ne s'encombre plus de ça, on travaille
  # avec la longueur possible de texte uniquement
  cursor_offset = 0

  # On boucle sur toutes les notes de l'extrait pour les afficher
  duplicate_titems = extrait_titems.reverse

  # Pour suivre l'index du mot
  index_titem_in_extrait = -1 # pour commencer à 0

  while titem = duplicate_titems.pop

    log_msg = []

    # On reset toujours le text-item pour forcer tous les recalculs
    titem.reset
    titem.index_in_extrait = (index_titem_in_extrait += 1)

    log_msg << "#{RC*2}* ÉTUDE DE ““#{titem.content.gsub(/\n/,'\n')}”” (index #{titem.index_in_extrait}) POUR OUTPUT"

    # On doit calculer la longeur que ce text-item va occuper. Cette longueur
    # dépend :
    #
    #   a) de la longueur du texte lui-même (ponctuation ou mot)
    #   b) de l'index dans la page courante (3 si "234")
    #   c) des proximités s'il y en a, et la place qu'elles occupent.
    #
    titem.calcule_longueurs(self)
    log_msg << "\t- Longueur (f_length) : #{titem.f_length}"

    # On a besoin de l'item suivant pour plusieurs choses :
    #   - savoir si le text-item courant est le dernier du texte
    #   - savoir si le text-item suivant est une ponctuation (si c'est une
    #     ponctuation, elle doit toujours être attachée au mot courant)
    next_titem = duplicate_titems[-1]
    if not next_titem.nil?
      next_titem.index_in_extrait = index_titem_in_extrait + 1
      next_titem.calcule_longueurs(self)
      log_msg << "\t- Longueur text-item suivant : #{next_titem.f_length}"
    end
    log_msg << "\t\t(item suivant : #{next_titem&.content.inspect})"

    # Faut-il coller le text-item courant au text-item suivant ?
    # (pour pouvoir compter la longueur qu'on obtiendrait). On doit coller
    # avec le mot suivant lorsque :
    #   - le mot suivant existe
    #   - le mot suivant est une ponctuation OU que le mot courant finit
    #     par une apostrophe
    next_must_be_joined = not(next_titem.nil?) && (next_titem.ponctuation? || titem.elized?)

    if next_titem.nil?
      log_msg << "\t\t= next_titem est nil"
    else
      if next_titem.mot?
        log_msg << "\t\t= next_titem est un mot"
      else
        log_msg << "\t\t= next_titem n'est pas un mot"
        if next_must_be_joined
          log_msg << "\t\t- titem doit être joint au suivant"
        else
          log_msg << "\t\t- titem ne doit pas être join au suivant"
        end
        # if FIRST_SIGN_PHRASE[next_titem.content[0]]
        #   log_msg << "\t\t= next_titem commence par un signe de début de phrase"
        # else
        #   log_msg << "\t\t= next_titem ne commence pas par un signe de début de phrase"
        # end
        # if next_titem.has_point?
        #   log_msg << "\t\t= next_titem contient un point quelconque"
        # else
        #   log_msg << "\t\t= next_titem ne contient pas de point"
        # end
        # if next_titem.new_paragraph?
        #   log_msg << "\t\t= tnext_titem contient un retour chariot"
        # else
        #   log_msg << "\t\t= tnext_titem ne contient pas de retour chariot"
        # end
        # if next_titem.ponctuation?
        #   log_msg << "\t\t= next_titem est une ponctuation"
        # else
        #   log_msg << "\t\t= next_titem n'est pas une ponctuation"
        # end
      end
    end

    # On a besoin de savoir si c'est le dernier text-item pour savoir ce que
    # l'on devra faire en cas d'ajout de blancs.
    is_last_titem = next_titem.nil?

    # On calcule le prochain offset (cursor_offset) pour voir si on doit passer à la
    # ligne avant d'ajouter de text-item.
    # Dans le nouveau calcul, on doit tenir compte du fait qu'on met toujours
    # les ponctuations et les retours chariot à la fin de la ligne, jamais au
    # début de la suivante.
    titem_total_len = titem.f_length.dup
    # On ajoute la longueur du text-item suivant si c'est une ponctuation.
    titem_total_len += next_titem.f_length if next_must_be_joined
    log_msg << "\t- Longueur Totale occupée par le text-item#{next_must_be_joined ? ' et le suivant' : EMPTY_STRING} : #{titem_total_len}"

    # Le décalage horizontal si on collait ce mot (et peut-être sa
    # ponctuation ou son retour chariot)
    next_offset_virtuel = cursor_offset + titem_total_len

    # Si le prochain offset, auquel on ajoute la valeur de la marge, est
    # supérieur à la longueur maximale de la ligne, alors il faut passer
    # à la ligne suivante
    if next_offset_virtuel < max_text_length
      # OK, on ne dépasse pas la longueur maximale.

      log_msg << "\t\t=== La nouvelle position du curseur sera #{next_offset_virtuel}"

    else

      log_msg << "\t  === Ce qui conduit le curseur à #{next_offset_virtuel}"
      log_msg << "\t=> next_offset_virtuel (#{next_offset_virtuel.inspect}) > max_text_length (#{max_text_length.inspect}) => On doit passer à la ligne suivante pour écrire “““#{titem.content}”””."

      # On finit la ligne avec les caractères manquants
      finir_ligne(current_line, ProxPage::LEFT_MARGIN + cursor_offset)

      # Si c'est le dernier item, on peut s'arrêter là.
      break if is_last_titem

      # Si ce n'est pas le dernier text-item à afficher, on doit passer à la
      # ligne suivante et ajouter la marge gauche (pour la lisibilité)
      current_line += 1
      log_msg << "\t\t* Incrémentation du numéro de ligne : #{current_line}"
      write_indentation(current_line)
      cursor_offset = 0

    end

    # *** On écrit LE TEXT-ITEM SUR LES TROIS LIGNES DE LA PHRASE ***

    write3lines(
      [
        titem.f_index,
        titem.f_content,
        titem.f_proximities
      ], current_line, ProxPage::LEFT_MARGIN + cursor_offset, titem.text_color, titem.prox_color
    )

    # On se place sur l'offset suivant
    cursor_offset += titem.f_length

    # Si le mot suivant doit être écrit aussi
    if next_must_be_joined
      log_msg << "\t  On ajoute l'item suivant"

      # On retire vraiment l'item de la liste et on incrémente vraiment
      # l'index du text-item dans la page (on ne l'avait fait que virtuellement
      # avant)
      duplicate_titems.pop
      index_titem_in_extrait += 1

      write3lines(
        [
          next_titem.f_index,
          next_titem.f_content,
          next_titem.f_proximities
        ], current_line, ProxPage::LEFT_MARGIN + cursor_offset, next_titem.text_color, next_titem.prox_color
      )

      # On se place sur l'offset suivant
      cursor_offset += next_titem.f_length

    end # fin de si le suivant doit être ajouté

    # Debug
    # -----
    #
    # log(log_msg.join(RC) + RC*3)
    ## Ce panneau réaffiche toutes les informations sur le découpage
    #
    #

  end # Fin de boucle sur tous les items à afficher

  # On finalise la ligne courante
  finir_ligne(current_line, ProxPage::LEFT_MARGIN + cursor_offset)

  # On ajoute une dernière ligne blanche pour que ce soit mieux
  current_line += 1
  write_blank_line(current_line * 3 + 1, 2)

  # Il faut se souvenir qu'on a regardé en dernier ce tableau
  Runner.itexte.config.save(last_first_index: from_item)
  log("<- ExtraitTexte#output")
end #/ output

# Méthode pour écrire une ou +nombre+ ligne vierge à la hauteur +top+
def write_blank_line(top, nombre = 1)
  large = Array.new(nombre, blank_line).join(RC)
  CWindow.textWind.writepos([top, 0], large, CWindow::TEXT_COLOR)
end #/ write_blank_line

# Méthode générale qui affiche les trois lignes pour le texte
#
# @Params
#   +treelines+   {Array} Les trois textes à écrire (index, texte, proximités)
#   +curline+     {Integer} La ligne virtuelle courante (rappel : une ligne
#                 virtuelle est égale à 3 lignes graphiques)
#   +curoff+      {Integer} Décalage horizontal du texte (cursor offset)
#   +color_prox+  {Integer} Indice de la couleur pour caractériser la proximité
#                 Quatre couleurs du vert au rouge suivant la proximité.
#
def write3lines treelines, curline, curoff, text_color = nil, color_prox = nil
  lgn_idx, lgn_titem, lgn_prox = treelines
  top = curline * 3 + 1 # +1 pour la ligne supérieure
  color_prox ||= CWindow::TEXT_COLOR
  text_color ||= CWindow::TEXT_COLOR
  CWindow.textWind.writepos([top,   curoff], lgn_idx,   CWindow::INDEX_COLOR)
  CWindow.textWind.writepos([top+1, curoff], lgn_titem, text_color)
  CWindow.textWind.writepos([top+2, curoff], lgn_prox,  color_prox)
end #/ write3lines

# Méthode graphique qui permet de "finir" une ligne affichée en ajoutant les
# espace au bout de la couleur normale.
def finir_ligne(current_line, curoff)
  dif = max_line_length - curoff
  manque = (SPACE * dif).freeze
  write3lines([manque,manque,manque], current_line, curoff)
end #/ finir_ligne

# @Return {String} une ligne vierge qui couvre toute la page
def blank_line
  @blank_line ||= SPACE * max_line_length
end #/ blank_line = SPACE * max_line_length

# @Return la longueur maximale que peut occuper une ligne
def max_line_length
  @max_line_length ||= ProxPage.max_line_length
end #/ max_line_length

# @Return {Integer} la longueur maximale du texte, hors marges. C'est-à-dire
# la longueur que peut vraiment avoir le texte dans l'affichage.
# Attention, la valeur est différente de celle dans ProxPage, pour le calcul
# des pages, où on laisse un tampon (voir pourquoi dans ProxPage)
def max_text_length
  @max_text_length ||= max_line_length - ( ProxPage::RIGHT_MARGIN + ProxPage::LEFT_MARGIN)
end #/ max_text_length

# Méthode graphique qui écrit une indentation sur les trois lignes de texte
def write_indentation(yindex)
  write3lines([SPACES_LEFT_MARGIN,SPACES_LEFT_MARGIN,SPACES_LEFT_MARGIN], yindex, 0)
end #/ write_indentation

# PRÉPARATION DES LISTES
#
# Méthode définissant les variables :
#   @extrait_titems       Text-items de l'extrait courant
#   @extrait_pre_titems   Text-items précédent l'extrait courant, à distance
#                         de proximité minimale.
#   @extrait_post_titems  Text-items succédant l'extrait courant, à distance
#                         de proximité minimale.
#
def prepare_listes
  # Les trois listes qui vont être définies ici
  @extrait_titems     = nil
  @extrait_pre_titems  = nil
  @extrait_post_titems = nil

  # La page courante
  # ipage.titems contient tous les text-items de la page, donc de l'extrait.
  # QUESTION quid si c'est un affichage :show xxxx ?
  ipage = ProxPage.current_page
  @extrait_titems = ipage.text_items

  # log("DB: #{itexte.db.path}")
  # log("hfrom_item (index #{from_item.inspect}): #{hfrom_item.inspect}")

  # On doit récupérer dans la base de données tous les text-items qui ont
  # un offset de la distance minimale commune avant
  # +offset_first+ Integer Décalage absolu du mot dans le texte. Cette valeur
  # est toujours juste puisqu'elle est recalculée chaque fois
  first_text_item = ipage.text_items.first
  offset_first = first_text_item.offset
  log("Offset du tout premier mot affiché : #{offset_first.inspect} (mot “#{first_text_item.content}” d'index #{first_text_item.index})")
  first_offset_avant = offset_first - itexte.distance_minimale_commune
  log("On doit prendre les text-items avant jusqu'à l'offset #{first_offset_avant.inspect}")
  # La requête String permettant de récupérer ces text-items
  request = "SELECT * FROM text_items WHERE Offset >= ? AND Offset < ? ORDER BY Offset ASC".freeze
  itexte.db.results_as_hash = true
  titems_avant = itexte.db.execute(request, first_offset_avant, offset_first)
  log("Nombre de titems trouvés avant : #{titems_avant.count}")

  # On instancie les text-items avant pour en faire des instances et
  # on règle sur index dans l'extrait affiché.
  idx = titems_avant.count + 1 # pour que le dernier soit à -1
  @extrait_pre_titems = titems_avant.collect do |hdata|
    TexteItem.instanciate(hdata, -(idx -= 1))
  end
  # log("@extrait_pre_titems = #{@extrait_pre_titems.inspect}")

  # On a besoin de l'offset du dernier mot pour savoir jusqu'où il faut
  # prendre la suite.
  last_text_item = ipage.text_items.last
  offset_last = last_text_item.offset
  last_offset_apres = offset_last + itexte.distance_minimale_commune
  request = "SELECT * FROM text_items WHERE Offset > ? AND Offset <= ? ORDER BY Offset ASC".freeze
  itexte.db.results_as_hash = true
  titems_apres = itexte.db.execute(request, offset_last, last_offset_apres)
  # log("titems_apres : #{titems_apres.inspect}")

  # On ajoute les instances des titems après (non affichés) aux titems de l'extrait
  @extrait_post_titems = titems_apres.collect do |hdata|
                          TexteItem.instanciate(hdata, idx += 1)
                        end

  # On remet les résultats de la base de données sans table, comme c'est par
  # défaut. Cela permet d'accélerer les traitements.
  itexte.db.results_as_hash = false

  ### Debug
  ### -----
  ###
  ### Décommenter pour débugger tous les items qui seront dans l'extrait,
  ### avant ou après
  # debug_trois_listes_titems
  ###
  ###

end #/ prepare_listes

# Méthode de débuggage pour voir les trois listes de l'extrait :
#   - les text-items de l'extrait lui-même
#   - les text-items avant, à une distance de distance_minimale_commune
#   - les text-items suivant, idem
def debug_trois_listes_titems
  delimitation = TIRET*80
  log("#{RC*2}#{delimitation}#{RC}Text-items dans l'extrait courant (from_item #{from_item})#{RC}")
  log("--- @extrait_pre_titems ---")
  mots = extrait_pre_titems.collect do |titem|
    "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
  end.join(RC)
  log(RC + mots)
  log("--- @extrait_titems ---")
  mots = extrait_titems.collect do |titem|
    "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
  end.join(RC)
  log(RC + mots)
  log("--- @extrait_post_titems ---")
  mots = extrait_post_titems.collect do |titem|
    "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
  end.join(RC)
  log(RC + mots)
  log(delimitation)
  log(RC*3)
end #/ debug_trois_listes_titems

# Retourne la liste des text-items de l'extrait
def extrait_titems ; @extrait_titems end
# Les text-items AVANT l'extrait affiché
# [1] Note : cette liste, comme la liste post_items, ne sert que pour définir
#     les proximités d'avec les premiers et derniers mots (autour)
def extrait_pre_titems; @extrait_pre_titems end
# Les text-items APRÈS l'extrait affiché
def extrait_post_titems; @extrait_post_titems end

# Actualisation de l'affichage
#
# [1] Ça ne coûte rien de tout recompter et ça évite de traiter des cas
#     différents (par exemple, on ne peut pas se contenter de traiter les
#     proximités depuis le mot changé, car il peut y avoir des modifications
#     avant aussi)
#
# +from_item+ n'est pas le @from_item de l'instance extrait mais l'index
# du mot à partir duquel on devrait recompter si on voulait vraiment
# économiser le travail.
#
def update(to_save = nil)
  recompte # C'est TexteExtrait#recompte, ici, pas Texte#recompte
  output
end #/ update

# Pour actualiser l'affichage, quand les informations ont changé, il faut
# principalement actualiser la donnée index_in_extrait
def recompte

  # Les items avant l'extrait
  # -------------------------
  # Ils n'ont pas besoin d'être recomptés au niveau de leur index, puisque
  # cet index ne peut pas être modifié. En revanche, on peut les reset(ter)
  # car leurs proximités peuvent avoir changé
  extrait_pre_titems.each do |titem|
    titem.reset
  end

  # Les items de l'extrait
  # -----------------------
  extrait_titems.each_with_index do |titem, idx|
    titem.index_in_extrait = idx
  end


  # Les items après l'extrait
  # --------------------------
  # Leur index peut évidemment avoir changé, si des mots ont été ajoutés
  # ou supprimés par exemple.
  idx = extrait_titems.count - 1 # -1 car on ajoute tout de suite 1
  extrait_post_titems.each do |titem|
    titem.reset
    titem.index_in_extrait = (idx += 1)
  end

end #/ recompte

end #/ExtraitTexte
