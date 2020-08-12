# encoding: UTF-8
require 'tempfile'

class ExtraitTexte
DEFAULT_NOMBRE_ITEMS  = 400 # c'est de toute façon le nombre de lignes qui importe
TEXTE_COLS_WIDTH      = 100
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :itexte, :from_item, :to_item

# Pour indiquer que l'extrait a été modifié
attr_accessor :modified

def initialize itexte, params
  # log("params: #{params.inspect}")
  @itexte     = itexte
  @from_item  = params[:from]
  @form_item = 0 if @from_item.nil? || @from_item < 0
  @to_item    = params[:to]
end #/ initialize

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
# texte.
# LENGTH_TEXT_IN_TEXT_WINDOW = 2000
LENGTH_TEXT_IN_TEXT_WINDOW = 1000 # pour essai
def output

  # Dans la nouvelle formule, on récolte les items dans la base de données
  # qui correspondent au panneau demandé. Ce panneau est défini par l'index
  # @from_item. Cet index définit un offset qu'il suffit de relever dans la
  # table text_items. Cet offset permet de définir les text-items à prendre
  # avant le premier mot.
  # Ensuite, on doit trouver le dernier mot, dont l'offset permettra de
  # définir le dernier mot qu'il faut relever.
  # Un extrait contient donc :
  #   titem d'offset offset-premier - distance_minimale commune
  #   jusque
  #   titem d'index @from_item
  #   jusque
  #   titem d'index @to_item (mais comment est-il calculé ? peut-être
  #   d'après l'offset du premier mot, aussi, sachant qu'on ne peut mettre
  #   qu'une certaine distance dans la fenêtre)
  #   jusque
  #   le titem d'offset offset-dernier + distance_minimale_commune


  CWindow.textWind.clear

  # *** Définitions préliminaires ***

  top_line_index = 0

  # On décale toujours d'une espace pour la lisibilité
  write_indentation(top_line_index)
  offset = 1

  # *** fin des préparations préliminaires ***

  # On boucle sur toutes les notes de l'extrait pour les afficher
  # Note : c'est la méthode propriété +extrait_titems+ qui va recueillir
  # les text-items à afficher ici.
  log("extrait_titems:#{extrait_titems.inspect}")
  extrait_titems.each_with_index do |titem, idx|

    # On reset toujours le text-item pour forcer tous les recalculs
    titem.reset

    # On doit calculer la longeur que ce text-item va occuper. Cette longueur
    # dépend :
    #
    #   a) de la longueur du texte lui-même (ponctuation ou mot)
    #   b) de l'index dans la page courante (3 si "234")
    #   c) des proximités s'il y en a.
    #
    # Noter que c'est ce calcul des longueurs qui va définir les proximités
    # du mot si c'est un mot et qu'elles existent.
    titem.calcule_longueurs(self)

    # On prend déjà le prochain offset pour voir si on doit passer à la
    # ligne avant d'ajouter de text-item.
    next_offset = offset + titem.f_length

    # On a besoin de savoir si c'est le dernier text-item pour savoir ce que
    # l'on devra faire en cas d'ajout de blancs.
    is_last_titem = extrait_titems[idx+1].nil?

    # Si le prochain offset obtenu est supérieur à la longueur maximale
    # de la ligne ou que c'est un nouveau paragraphe, on passe à la ligne
    # suivante
    if ( next_offset > max_line_length ) || titem.new_paragraphe?
      # On finit la ligne avec les caractères manquants
      finir_ligne(top_line_index, offset)

      # Si c'est le dernier item, on peut s'arrêter là.
      if is_last_titem
        break
      else
        # Si ce n'est pas le dernier text-item à afficher, on doit passer à la
        # ligne suivante et ajouter une espace au début (pour la lisibilité)
        top_line_index += 3
        write_indentation(top_line_index)
        offset = 1 # car l'indentation est de 1 caractère
        next if titem.new_paragraphe?
      end
    end

    # *** C'est ici qu'on écrit les trois lignes de la phrase
    write3lines(
      [
        titem.f_index(idx),
        titem.f_content,
        titem.f_proximities
      ], top_line_index, offset, titem.prox_color
    )

    # On se place sur l'offset suivant en fonction de la longueur affichée
    # du text-item
    offset += titem.f_length

  end # Fin de boucle sur tous les items à afficher

  # On finit la dernière ligne pour que ce soit plus propre
  finir_ligne(top_line_index, offset)

  # On peut définir le dernier index d'item de l'extrait, c'est utile pour
  # d'autres méthodes.
  @to_item = extrait_titems.last.index

  # On actualise le nombre dans la barre de statut
  CWindow.init_status_and_cursor

  # Il faut se souvenir qu'on a regardé en dernier ce tableau
  Runner.itexte.config.save(last_first_index: from_item)
  log("<- ExtraitTexte#output")
end #/ output

def finir_ligne(top_line_index, offset)
  manque = (SPACE * (max_line_length - offset)).freeze
  write3lines([manque,manque,manque], top_line_index, offset)
end #/ finir_ligne

def max_line_length
  @max_line_length ||= begin
    mll = Curses.cols - 6
    mll = TEXTE_COLS_WIDTH if mll > TEXTE_COLS_WIDTH
    mll
  end
end #/ max_line_length

def write_indentation(yindex)
  write3lines([SPACE,SPACE,SPACE], yindex, 0)
end #/ write_indentation

# Les text-items AVANT l'extrait affiché
# [1] Note : cette liste, comme la liste post_items, ne sert que pour définir
#     les proximités d'avec les premiers et derniers mots (autour)
def extrait_pre_items; @extrait_pre_items end
# Les text-items APRÈS l'extrait affiché
def extrait_post_items; @extrait_post_items end

def extrait_titems
  @extrait_titems ||= begin
    # La liste qui va contenir tous les items de l'extrait courant
    extitems = []

    # Pour pouvoir récupérer les données sous forme de Hash.
    # Attention :
    #   * les clés sont des strings
    #   * les noms de colonnes sont avec capitales ("Offset", "Content", etc.)
    itexte.db.results_as_hash = true

    hfrom_item = itexte.db.get_titem_by_index(from_item)
    if hfrom_item.nil?
      raise "Grave erreur, le text-item d'index #{from_item.inspect} est introuvable dans la DB"
    end
    # log("DB: #{itexte.db.path}")
    # log("hfrom_item (index #{from_item.inspect}): #{hfrom_item.inspect}")
    # On doit récupérer tous les items qui ont un offset de la distance minimale
    # commune avant
    offset_first = hfrom_item['Offset']
    first_offset_avant = offset_first - itexte.distance_minimale_commune
    titems_avant = itexte.db.db.execute("SELECT * FROM text_items WHERE Offset >= ? AND Offset < ? ORDER BY Offset ASC".freeze, first_offset_avant, offset_first)
    log("#{RC*3}+++ titems_avant : #{titems_avant.inspect}")

    # On ajoute les instances des titems courant aux titems de l'extrait
    idx = titems_avant.count
    @extrait_pre_items = titems_avant.collect do |hdata|
      titem = TexteItem.instanciate(hdata)
      titem.index_in_extrait = -(idx -= 1)
      titem
    end

    # On ajoute le premier items à la liste des items de l'extrait
    extitems << TexteItem.instanciate(hfrom_item)

    offset_last_mot = offset_first + LENGTH_TEXT_IN_TEXT_WINDOW
    titems_dedans = itexte.db.db.execute("SELECT * FROM text_items WHERE Offset > ? AND Offset < ? ORDER BY Offset ASC".freeze, offset_first, offset_last_mot)
    # log("#{RC*3}+++ titems_dedans: #{titems_dedans.inspect}")

    # On ajoute les instances des titems après (non affichés) aux titems de l'extrait
    extitems += titems_dedans.collect { |hdata| TexteItem.instanciate(hdata) }

    # On définit l'index dans l'extrait de chaque text-item.
    # Noter qu'il ne faut pas le faire au fur et à mesure de la composition
    # de la page (dans `output`) car sinon, si l'item 34 est en proximité avec
    # l'item 39, au moment où on écrit #34 et ses proximités, l'index n'est pas
    # encore défini pour #39.
    extitems.each_with_index { |i, idx| i.index_in_extrait = idx }

    offset_last = titems_dedans.last['Offset']
    last_offset_apres = offset_last + itexte.distance_minimale_commune
    titems_apres = itexte.db.db.execute("SELECT * FROM text_items WHERE Offset > ? AND Offset <= ? ORDER BY Offset ASC".freeze, offset_last, last_offset_apres)
    # log("titems_apres : #{titems_apres.inspect}")

    # On ajoute les instances des titems après (non affichés) aux titems de l'extrait
    idx = titems_avant.count + extitems.count - 1 # -1 car on ajoute tout de suite 1
    @extrait_post_items = titems_apres.collect do |hdata|
      titem = TexteItem.instanciate(hdata)
      titem.index_in_extrait = (idx += 1)
      titem
    end

    # On remet les résultats de la base de données sans table, comme c'est par
    # défaut. Cela permet d'accélerer les traitements.
    itexte.db.results_as_hash = false

    extitems
  end
end #/ extrait_titems

def write3lines treelines, top, offset, color_prox = nil
  idx, titem, prox = treelines
  CWindow.textWind.writepos([top,   offset], idx,   CWindow::INDEX_COLOR)
  CWindow.textWind.writepos([top+1, offset], titem,   CWindow::TEXT_COLOR)
  CWindow.textWind.writepos([top+2, offset], prox,  color_prox || CWindow::RED_COLOR)
end #/ write3lines

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
  # Pour indiquer que lorsqu'on passera à un autre extrait (ou tout de suite)
  # il faudra enregistrer les nouvelles valeurs. Noter qu'ici on n'indique pas
  # que le texte a été modifié. Car on peut abandonner toutes les modifications
  # en passant à une autre page ou en quittant l'application.
  if to_save === true
    self.modified = true
  end
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
  extrait_pre_items.each do |titem|
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
  extrait_post_items.each do |titem|
    titem.reset
    titem.index_in_extrait = (idx += 1)
  end

end #/ recompte

end #/ExtraitTexte
