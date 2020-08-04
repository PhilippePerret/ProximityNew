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



# ---------------------------------------------------------------------
#
#   Opérations sur le texte
#
# ---------------------------------------------------------------------

# Remplacer un mot par un ou des autres
# Le remplacement consiste à supprimer l'élément courant et à insérer le
# nouvel élément à la place (ou *les* nouveaux éléments)
def replace(params)
  CWindow.log("Remplacement du/des mot/s #{params[:at]} par “#{params[:content]}”")
  params.merge!(real_at: AtStructure.new(params[:at], from_item))
  remove(params.merge(noupdate: true))
  insert(params)
end #/ replace

# Suppression d'un ou plusieurs mots
def remove(params)
  params[:real_at] ||= begin
    AtStructure.new(params[:at], from_item).tap { |at| params.merge!(real_at: at) }
  end
  at = params[:real_at]
  if at.range?
    Runner.itexte.items.slice!(at.from, at.nombre)
  else
    at.list.each {|idx| Runner.itexte.items.slice!(idx)}
  end
  update(params[:real_at].at) unless params[:noupdate]
end #/ remove

# Insert un ou plusieurs mots
def insert(params)
  params[:real_at] ||= AtStructure.new(params[:at], from_item)
  CWindow.log("Insertion de “#{params[:content]}”#{params[:real_at].to_s} (avant “#{Runner.itexte.items[params[:real_at].at].content}”)")
  new_mots = Lemma.parse_str(params[:content], format: :instances)
  Runner.itexte.items.insert(params[:real_at].at, *new_mots)
  update(params[:real_at].at) unless params[:noupdate]
end #/ insert

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

# Transformer le params[:at] en ce qu'il est vraiment, en sachant qu'il peut
# être défini :
#   - par un chiffre seul     12
#   - par un range            12-14     de douze à quatorze
#   - par une liste           12,14,17    12, 14 et 17
#
# En sachant aussi que l'index donné est l'index relatif à la fenêtre
class AtStructure
  attr_reader :at, :from, :to, :nombre, :list, :at_init, :first_index
  def initialize(at_init, first_index)
    @at_init = at_init
    @first_index = first_index
    parse
  end #/ initialize
  def parse
    if at_init.match?(TIRET) # => un rang
      @from, @to = at_init.split(TIRET).collect{|i|i.to_i + first_index}
      @at = @from # par exemple pour replace
      @nombre = @to - @from + 1
      @is_a_range = true
    elsif at_init.match?(VG)
      @list = at_init.split(VG).collect{|i|i.strip.to_i + first_index}
      @is_a_list = true
    else
      @at = at_init.to_i + first_index
      @list = [@at] # pour simplifier certaines méthodes
    end
  end #/ parse

  def range?
    @is_a_range === true
  end #/ range?
  def list?
    @is_a_list === true
  end #/ list?

  # Retourne le at en version humaine
  def to_s
    if range?
      "de #{from} à #{to} (#{nombre})".freeze
    elsif list?
      "pour les index #{list.join(VGE)}".freeze
    else
      "pour l’index #{at}".freeze
    end
  end #/ to_s
end
