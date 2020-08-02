# encoding: UTF-8
class ExtraitTexte
DEFAULT_NOMBRE_ITEMS = 150
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :itexte, :from_item, :to_item
def initialize itexte, params
  log("params: #{params.inspect}")
  @itexte     = itexte
  @from_item  = params[:from] || 0
  @to_item    = params[:to] || (@from_item + DEFAULT_NOMBRE_ITEMS)
end #/ initialize

# Sortie de l'extrait. La mise en forme est assez complexe puisqu'elle
# doit mettre les index des mots ainsi que leur distance de proximité lorsqu'il
# y a proximité.
# On fonctionne ligne par ligne en sachant qu'une ligne est en réalité
# trois lignes l'une sur l'autre :
#   - ligne des index (avec index du mot en gris)
#   - ligne des mots proprement dit
#   - ligne des distances
def output
  log("-> ExtraitTexte#output")
  CWindow.textWind.clear

  ary_items = []
  all_lines = []

  # TODO Isoler, plus tard
  max_line_length = Curses.cols - 6
  max_line_length = 80 if max_line_length > 80

  top_line_index = 0

  # Décalage horizontal courant
  offset = 0
  write3lines([SPACE,SPACE,SPACE], top_line_index, offset)
  offset = 1

  # On boucle pour trouver

  # On boucle sur chaque item qui doit être affiché
  (from_item..to_item).each_with_index do |idx, idx_extrait|
    # S'il n'y a plus de text-item, on arrête
    mot = itexte.items[idx] || break
    # log("mot: #{mot.inspect}")
    # Si la ligne, avec ce mot, dépasse la valeur maximale, on
    # passe à la ligne suivante
    if (offset + mot.f_length > max_line_length) || mot.new_paragraphe?
      manque = (' ' * (max_line_length - offset)).freeze
      # CWindow.textWind.writepos([top_line_index, offset], manque)
      # CWindow.textWind.writepos([top_line_texte, offset], manque)
      # CWindow.textWind.writepos([top_line_proxi, offset], manque)
      write3lines([manque,manque,manque], top_line_index, offset)
      # On passe à la ligne (seulement si on n'est pas sur le dernier mot)
      unless itexte.items[idx + 1].nil?
        top_line_index += 3
        offset = 0
        write3lines([SPACE,SPACE,SPACE], top_line_index, offset)
        offset = 1
        next if mot.new_paragraphe?
      else
        break
      end
    end
    write3lines([mot.f_index(idx_extrait),mot.f_content,mot.f_proximities], top_line_index, offset)
    offset += mot.f_length

    # Pour voir mot à mot
    # break if CWindow.textWind.curse.getch.to_s == 'q'
  end
  log("<- ExtraitTexte#output")
end #/ output

def write3lines treelines, top, offset
  idx, mot, prox = treelines
  CWindow.textWind.writepos([top,   offset], idx,   CWindow::INDEX_COLOR)
  CWindow.textWind.writepos([top+1, offset], mot,   CWindow::TEXT_COLOR)
  CWindow.textWind.writepos([top+2, offset], prox,  CWindow::RED_COLOR)
end #/ write3lines
end #/ExtraitTexte
