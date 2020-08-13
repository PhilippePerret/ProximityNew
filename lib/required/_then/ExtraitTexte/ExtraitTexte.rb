# encoding: UTF-8
require 'tempfile'

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

# Pour indiquer que l'extrait a été modifié
attr_accessor :modified

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
    @page = ProxPage.pages[params[:numero_page]]
    @from_item = @page.from
    @to_item = @page.to
  elsif params.key?(:index)
    @page = nil
    @from_item = nil
    case params[:index_is]
    when :absolu
      @from_item = params[:index]
    when :in_page
      @page = ProxPage.page_from_index_mot(params[:index])
      @from_item = @page.from
      @to_item = @page.to
    end
  end
  # Pour forcer la relève
  @extrait_titems = nil
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
# texte. Ce nombre peut être élevé puisque c'est en fait le nombre de
# lignes occupées qui va décider du nombre de mots.
LENGTH_TEXT_IN_TEXT_WINDOW = 1500 # pour essai

# Le nombre d'espaces laissés à droite pour la marge
RIGHT_MARGIN = 2
# Idem à gauche
LEFT_MARGIN = 2
#
SPACES_LEFT_MARGIN = (SPACE * LEFT_MARGIN).freeze

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
  offset = LEFT_MARGIN

  # Pour retenir le véritable dernier index affiché
  real_last_index = nil

  # *** fin des préparations préliminaires ***

  # On boucle sur toutes les notes de l'extrait pour les afficher
  # Note : c'est la méthode propriété +extrait_titems+ qui va recueillir
  # les text-items à afficher ici.
  # log("extrait_titems:#{extrait_titems.inspect}") # ATTENTION : prend de la place si gros texte
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
    if ( next_offset > (max_line_length + LEFT_MARGIN) ) || titem.new_paragraphe?
      # On finit la ligne avec les caractères manquants
      finir_ligne(top_line_index, offset)

      # Si c'est le dernier item, on peut s'arrêter là.
      if is_last_titem
        real_last_index = idx
        break
      else
        # Si ce n'est pas le dernier text-item à afficher, on doit passer à la
        # ligne suivante et ajouter une espace au début (pour la lisibilité)
        top_line_index += 3
        # Mais si ce nombre n'est plus inférieur à la hauteur du texte (écran),
        # on doit s'arrêter là
        if top_line_index + 3 > CWindow.hauteur_texte - 1
          real_last_index = idx
          break
        end
        # Sinon, on peut poursuivre sur la ligne suivante
        write_indentation(top_line_index)
        offset = LEFT_MARGIN
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

    # Si on devait s'arrêter là, ce serait le vrai dernier index
    # Noter qu'il est défini plusieurs fois ci-dessous quand on
    # stoppe la boucle.
    real_last_index = idx

    # On se place sur l'offset suivant en fonction de la longueur affichée
    # du text-item
    offset += titem.f_length

  end # Fin de boucle sur tous les items à afficher

  # On ajoute une dernière ligne blanche pour que ce soit mieux
  CWindow.textWind.writepos([top_line_index,0], SPACE*(max_line_length+LEFT_MARGIN+RIGHT_MARGIN), CWindow::INDEX_COLOR)

  # On peut définir le dernier index d'item de l'extrait, c'est utile pour
  # d'autres méthodes. Noter que pour les pages, ça devrait être assez
  # juste.
  @to_item = real_last_index

  # Il faut se souvenir qu'on a regardé en dernier ce tableau
  Runner.itexte.config.save(last_first_index: from_item)
  log("<- ExtraitTexte#output")
end #/ output

def finir_ligne(top_line_index, offset)
  manque = (SPACE * ((max_line_length - offset) + LEFT_MARGIN + RIGHT_MARGIN)).freeze
  write3lines([manque,manque,manque], top_line_index, offset)
end #/ finir_ligne

# @Return la longueur maximale que peut occuper une ligne
def max_line_length
  @max_line_length ||= ProxPage.max_line_length
end #/ max_line_length

def write_indentation(yindex)
  write3lines([SPACES_LEFT_MARGIN,SPACES_LEFT_MARGIN,SPACES_LEFT_MARGIN], yindex, 0)
end #/ write_indentation

# Les text-items AVANT l'extrait affiché
# [1] Note : cette liste, comme la liste post_items, ne sert que pour définir
#     les proximités d'avec les premiers et derniers mots (autour)
def extrait_pre_items; @extrait_pre_items end
# Les text-items APRÈS l'extrait affiché
def extrait_post_items; @extrait_post_items end

# Retourne la liste des text-items de l'extrait
# Définit en même temps les text-items avant et après.
# Noter que le travail est différent suivant qu'il s'agissent d'une page
# ou d'un extrait "dans l'absolu" c'est-à-dire à partir d'un index quelconque.
def extrait_titems
  @extrait_titems ||= begin
    # Pour pouvoir récupérer les données sous forme de Hash.
    # Attention :
    #   * les clés sont des strings
    #   * les noms de colonnes sont avec capitales ("Offset", "Content", etc.)
    itexte.db.results_as_hash = true

    # On prend dans la DB le tout premier mot qui doit être affiché dans la
    # fenêtre. Cet text-item doit obligatoirement exister, sinon on lève une
    # exception.
    # +hfrom+ est un Hash contenant les données du mot.
    hfrom_item = itexte.db.get_titem_by_index(from_item)
    # Si ce n'est pas un mot, on prend le précédent, car on commence toujours
    # par un mot (pour l'esthétique)
    if hfrom_item['IsMot'] == 'FALSE'
      log("On doit prendre l'item d'avant pour avoir un Mot.")
      @from_item -= 1
      hfrom_item = itexte.db.get_titem_by_index(from_item)
    end
    if hfrom_item.nil?
      raise "Grave erreur, le text-item d'index #{from_item.inspect} est introuvable dans la DB"
    end

    # log("DB: #{itexte.db.path}")
    # log("hfrom_item (index #{from_item.inspect}): #{hfrom_item.inspect}")

    # On doit récupérer dans la base de données tous les text-items qui ont
    # un offset de la distance minimale commune avant
    # +offset_first+ Integer Décalage absolu du mot dans le texte. Cette valeur
    # est toujours juste puisqu'elle est recalculée chaque fois
    offset_first = hfrom_item['Offset']
    log("Offset du tout premier mot affiché : #{offset_first.inspect} (mot “#{hfrom_item['Content']}” d'index #{from_item})")
    first_offset_avant = offset_first - itexte.distance_minimale_commune
    log("On doit prendre les text-items avant jusqu'à l'offset #{first_offset_avant.inspect}")
    # La requête String permettant de récupérer ces text-items
    request = "SELECT * FROM text_items WHERE Offset >= ? AND Offset < ? ORDER BY Offset ASC".freeze
    titems_avant = itexte.db.db.execute(request, first_offset_avant, offset_first)
    log("Nombre de titems trouvés : #{titems_avant.count}")

    # On instancie les text-items avant pour en faire des instances et
    # on règle sur index dans l'extrait affiché.
    idx = titems_avant.count + 1 # pour que le dernier soit à -1
    @extrait_pre_items = titems_avant.collect do |hdata|
      TexteItem.instanciate(hdata, -(idx -= 1))
    end

    # On cherche les text-items qui vont se trouver dans la fenêtre
    # Si on connait @to_item, comme pour une page, on les relève simplement.
    # Sinon, il faut en relever une certaines quantité jusqu'à atteindre la
    # quantité voulue par rapport à la page. On se sert pour cela des méthodes
    # de ProxPage qui sait calculer les longueurs de page en fonction de
    # l'interface actuelle.
    if @to_item.nil?
      @to_item = ProxPage.last_item_page_from_index(itexte, from_item)
    end
    log("=== @to_item : #{@to_item.inspect}")

    request = "SELECT * FROM text_items WHERE `Index` >= ? AND `Index` <= ? ORDER BY `Index` ASC".freeze
    titems_dedans = itexte.db.db.execute(request, from_item, to_item)

    # On instancie tous les items qui peuvent appartenir à l'extrait
    # On définit aussi l'index dans l'extrait de chaque text-item.
    # Noter qu'il ne faut pas le faire au fur et à mesure de la composition
    # de la page (dans `output`) car sinon, si l'item 34 est en proximité avec
    # l'item 39, au moment où on écrit #34 et ses proximités, l'index n'est pas
    # encore défini pour #39.
    idx = -1 # on commencera à 1 car c'est le premier text-item qui porte
            # l'index 0
    extitems =  titems_dedans.collect do |hdata|
                  TexteItem.instanciate(hdata, idx += 1)
                end
    # On a besoin de l'offset du dernier mot pour savoir jusqu'où il faut
    # prendre la suite.
    offset_last = titems_dedans.last['Offset']
    last_offset_apres = offset_last + itexte.distance_minimale_commune
    request = "SELECT * FROM text_items WHERE Offset > ? AND Offset <= ? ORDER BY Offset ASC".freeze
    titems_apres = itexte.db.db.execute(request, offset_last, last_offset_apres)
    # log("titems_apres : #{titems_apres.inspect}")

    # On ajoute les instances des titems après (non affichés) aux titems de l'extrait
    @extrait_post_items = titems_apres.collect do |hdata|
                            TexteItem.instanciate(hdata, idx += 1)
                          end

    # On remet les résultats de la base de données sans table, comme c'est par
    # défaut. Cela permet d'accélerer les traitements.
    itexte.db.results_as_hash = false

    # Pour débugger tous les items qui seront dans l'extrait, avant ou
    # après
    if false # mettre "true" pour voir le débug
      delimitation = TIRET*80
      log("#{RC*2}#{delimitation}#{RC}Text-items dans l'extrait courant (from_item #{from_item})#{RC}")
      log("--- @extrait_pre_items ---")
      mots = extrait_pre_items.collect do |titem|
        "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
      end.join(RC)
      log(RC + mots)
      log("--- @extrait_titems ---")
      mots = extitems.collect do |titem|
        "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
      end.join(RC)
      log(RC + mots)
      log("--- @extrait_post_items ---")
      mots = extrait_post_items.collect do |titem|
        "    * “#{titem.content.gsub(/\n/,'\n')}” - offset: #{titem.offset} - index: #{titem.index_in_extrait}".freeze
      end.join(RC)
      log(RC + mots)
      log(delimitation)
      log(RC*3)
    end

    extitems # => @extrait_titems
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
