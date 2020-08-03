# encoding: UTF-8
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

  # Pour conserver le vrai dernier indice d'item
  real_last_idx = nil

  # On boucle sur chaque item qui doit être affiché
  (from_item..to_item).each_with_index do |idx, idx_extrait|
    # S'il n'y a plus de text-item, on arrête
    mot = itexte.items[idx] || break
    real_last_idx = idx

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
        break if top_line_index + 2 > CWindow.top_ligne_texte_max
        offset = 0
        write3lines([SPACE,SPACE,SPACE], top_line_index, offset)
        offset = 1
        next if mot.new_paragraphe?
      else
        break
      end
    end
    write3lines([mot.f_index(idx_extrait),mot.f_content,mot.f_proximities], top_line_index, offset, mot.prox_color)
    offset += mot.f_length

    # Pour voir chaque mot s'afficher l'un après l'autre
    # break if CWindow.textWind.curse.getch.to_s == 'q'
  end
  @to_item = real_last_idx
  CWindow.status("From #{@from_item} to #{@to_item}")
  log("<- ExtraitTexte#output")
end #/ output

def write3lines treelines, top, offset, color_prox = nil
  idx, mot, prox = treelines
  CWindow.textWind.writepos([top,   offset], idx,   CWindow::INDEX_COLOR)
  CWindow.textWind.writepos([top+1, offset], mot,   CWindow::TEXT_COLOR)
  CWindow.textWind.writepos([top+2, offset], prox,  color_prox || CWindow::RED_COLOR)
end #/ write3lines



# ---------------------------------------------------------------------
#
#   Opérations sur le texte
#
# ---------------------------------------------------------------------
def insert(params)
  CWindow.log("Je dois insérer le texte “#{params[:content]}” à l'index #{params[:at]} (avant “#{Runner.itexte.items[params[:at]].content}”)")
  new_mots = Lemma.parse_str(params[:content], format: :instances)
  times = [[Time.now.to_f, 'démarrage']]
  Runner.itexte.items.insert(params[:at], *new_mots)
  times << [Time.now.to_f, 'insertion']
  Runner.itexte.recompte(from: params[:at])
  times << [Time.now.to_f, 'recomptage']

  # On rafraichit l'affichage
  output

  # Affichage des temps
  times.each_with_index do |dtime, idx|
    # log("#{RC}#{new_mots}#{RC}")
    if idx == 0
      log("Start: #{dtime.first}")
    else
      log("#{dtime.last}: #{dtime.first - times[idx-1].first}")
    end
  end
end #/ insert
end #/ExtraitTexte
