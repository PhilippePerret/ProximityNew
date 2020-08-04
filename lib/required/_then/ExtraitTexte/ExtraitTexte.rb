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
def initialize itexte, params
  # log("params: #{params.inspect}")
  @itexte     = itexte
  @from_item  = params[:from] || 0
  @to_item    = params[:to] || (@from_item + DEFAULT_NOMBRE_ITEMS)
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
def output
  log("-> ExtraitTexte#output")
  CWindow.textWind.clear

  max_line_length = Curses.cols - 6
  max_line_length = TEXTE_COLS_WIDTH if max_line_length > TEXTE_COLS_WIDTH

  top_line_index = 0

  # Décalage horizontal courant
  offset = 0
  # On décale toujours d'une espace pour la lisibilité
  write3lines([SPACE,SPACE,SPACE], top_line_index, offset)
  offset = 1

  # Pour conserver le vrai dernier indice d'item, car to_item dépasse
  # peut-être le nombre d'items
  real_last_idx = nil

  # On boucle sur chaque item qui doit être affiché
  log("On doit afficher les items de #{from_item} à #{to_item} (nombre total : #{itexte.items.count})")
  (from_item..to_item).each_with_index do |idx, idx_extrait|
    # S'il n'y a plus de text-item, on arrête
    titem = itexte.items[idx] || begin
      break
    end
    real_last_idx = idx

    # On doit calculer les longueurs du mot (index, mot, proximités)
    titem.calcule_longueurs

    # log("titem: #{titem.inspect}")
    # Si la ligne, avec ce titem, dépasse la valeur maximale, on
    # passe à la ligne suivante
    if (offset + titem.f_length > max_line_length) || titem.new_paragraphe?
      manque = (' ' * (max_line_length - offset)).freeze
      write3lines([manque,manque,manque], top_line_index, offset)
      # On passe à la ligne (seulement si on n'est pas sur le dernier titem)
      unless itexte.items[idx + 1].nil?
        top_line_index += 3
        break if top_line_index + 2 > CWindow.top_ligne_texte_max
        offset = 0
        write3lines([SPACE,SPACE,SPACE], top_line_index, offset)
        offset = 1
        next if titem.new_paragraphe?
      else
        break
      end
    end
    # C'est ici que sont véritablement écrite les 3 lignes du mot/nonmot
    write3lines(
      [
        titem.f_index(idx_extrait),
        titem.f_content,
        titem.f_proximities
      ],
      top_line_index, offset, titem.prox_color
    )
    offset += titem.f_length

    # Pour voir chaque titem s'afficher l'un après l'autre
    # break if CWindow.textWind.curse.getch.to_s == 'q'
  end #/loop sur les mots à voir

  @to_item = real_last_idx
  msg = "From #{@from_item} to #{@to_item}"
  msg << " (dernier)" if (@to_item + 1 >= itexte.items.count)
  CWindow.status(msg)

  # Il faut se souvenir qu'on a regardé en dernier ce tableau
  Runner.itexte.config.save(last_first_index: from_item)
  log("<- ExtraitTexte#output")
end #/ output

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
def update(from_item = 0)
  Runner.itexte.recompte(from: 0) # [1]
  output
end #/ update
end #/ExtraitTexte
