# encoding: UTF-8
=begin
  Module pour l'aide

  L'aide a son propre attente interactive.
=end
class Help

# Constantes pour l'affichage
MARGIN_WIDTH  = 4
LEFT_MARGIN   = SPACE * MARGIN_WIDTH
RIGHT_MARGIN  = SPACE * MARGIN_WIDTH
LINE_WIDTH    = 80
INVITE = "Affichage de l'aide (ligne %{first} à %{last}).#{RC}q : revenir au texte".freeze

TDM = [
  {titre:"Introduction", file: 'introduction'},
  {titre:'Commandes fréquentes', file:'useful_commands'},
  {titre:'Ouverture d’un texte', file:'open_text'},
  {titre:'Parsing', file:'parsing_text'},
  {titre:'Modification du texte', file:'modify_text'},
  {titre:'Reconstruction du texte', file:'rebuilding_text'},
  {titre:'Listes spéciales', file:'special_lists'},
  {titre:'Autres commandes', file:'other_commands'},
  {titre:'Fin de l’aide', file:'fin'},
]

TDM_DEVELOPPER = [
  {titre:'Introduction au développement', file:'xdev/introduction'}
]

class << self
  # Destinataire de l'aide, l'utilisateur ou le développeur
  attr_accessor :destinataire

  # L'index du fichier d'aide courant, dans TDM ou TDM_DEVELOPPER
  attr_accessor :aide_index
  # L'instance du fichier d'aide courant
  attr_reader :current


  # Affichage de l'aide
  # Si +suite_cmd+ est nil, on affiche l'aide entière. Sinon, on affiche
  # cette aide en particulier.
  #
  # Nouveau fonctionnement : on peut appeler l'aide par petits bouts ou
  # en entier. En entier, elle est simplement reconstituée à partir des
  # fichiers du dossier 'textes'
  def show(suite_cmd)
    define_current_aide(suite_cmd.shift)
    options = optionize(suite_cmd)
    dispatch_options(options)
    current.output
    interact
    on_quit
  end #/ show

  # Méthode qui définit, au début de l'aide, le fichier d'aide à utiliser et
  # son index.
  # +which+ est le premier argument donné à la commande :help. Il peut être
  # nil, dans ce cas, on affiche le premier fichier d'aide. Sinon, on cherche
  # à quel fichier il peut appartenir et on en déduit l'index et le fichier
  # @Return
  #   void
  # @Produit
  #   @current    L'instance du fichier d'aide courant
  def define_current_aide(which)
    @aide_index = nil
    if not(which.nil?)
      TDM.each do |daide, idx_aide|
        if daide[:file].match?(which) || daide[:titre].match?(which)
          @aide_index = idx_aide
          break
        end
      end
    end

    # Si on n'a pas trouvé le fichier d'aide voulu ou s'il n'a pas été
    # défini.
    @aide_index = 0 if @aide_index.nil?

    # Définition du fichier d'aide courant
    @current = new(TDM[@aide_index])
  end #/ define_current_aide

  # Pour intéragir avec l'user
  # Cinq possibilités :
  #   - descendre dans le texte
  #   - remonter dans le texte
  #   - passer au texte suivant
  #   - passer au texte précédent
  #   - quitter l'aide
  def interact
    while true
      case CWindow.wait_for_user(keys: ['q', 258, 259, 260, 261])
      when 258
        current.next_page || next_aide
      when 259
        current.prev_page || prev_aide
      when 261 # flèche droite
        next_aide
      when 260 # flèche gauche
        prev_aide
      when 'q' then
        break
      end
    end
  end #/ interact

  # Pour afficher le fichier d'aide suivant
  def next_aide
    next_data = TDM[aide_index + 1]
    if not(next_data.nil?)
      @current = new(next_data)
      @current.output
      @aide_index += 1
    else
      log("Fin de l'aide. Pas de nouveau fichier.".freeze, true)
    end
  end #/ next_aide

  def prev_aide
    if aide_index > 0
      @current = new(TDM[@aide_index -= 1])
      @current.output
    else
      log("Début de l'aide. Aucun texte avant.".freeze, true)
    end
  end #/ prev_aide

  # @Return une ligne vierge (pour mettre en entête et en pied de page de
  # l'aide)
  def blank_line
    @blank_line ||= LEFT_MARGIN + SPACE * LINE_WIDTH + RIGHT_MARGIN
  end #/ blank_line

  # @Return le nombre maximum de ligne pour l'affichage courant, en fonction
  # de la hauteur du texte courant
  def max_lines_count
    @max_lines_count ||= Curses.lines - 15
  end #/ max_lines_count

  # On dispatche les options dans les variables de classe de l'aide
  def dispatch_options(options)
    self.destinataire = options[:destinataire]
  end #/ dispatch_options

  # On définit les options à utiliser pour l'appel de l'aide courant
  def optionize(suite_cmd)
    options = {destinataire: :user}
    first_arg = suite_cmd.shift
    case first_arg
    when 'dev', 'developper', 'development', 'developpement'
      options[:destinataire] = :developper
    end
    return options
  end #/ optionize

  def on_quit
    log("Retour au texte.", true)
    Runner.iextrait&.output
  end #/ on_quit

  # @Return le chemin d'accès complet au fichier d'aide d'affixe +affixe+
  def path(affixe)
    File.join(textes_folder, "#{affixe}.md")
  end #/ path

  def textes_folder
    @textes_folder ||= File.join(LIB_FOLDER,'required','_then','Help','textes')
  end #/ textes_folder

end # /<< self

# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

# Texte complet de l'aide
attr_reader :text
# Pour connaitre la première et dernière ligne affichée
attr_reader :first_line, :last_line

def initialize data
  @data = data
  @text = File.read(classe.path(data[:file]))
end #/ initialize

# Pour sortir le texte (i.e. l'afficher à l'écran)
# +from_line+ est l'indice de la première ligne à afficher, à partir de 0.
def output(first_line = nil)
  show_lines(first_line || 0)
end #/ output

def prev_page
  unless first_line == 0
    show_lines(first_line - classe.max_lines_count)
    return true
  end
end #/ prev_page

def next_page
  unless last_line >= lines_count
    show_lines(first_line + classe.max_lines_count)
    return true
  end
end #/ next_page

# Affichage à l'écran des lignes à partir de la ligne +first_line+ (0-start)
def show_lines(first_line)
  @first_line = first_line
  @last_line = first_line + classe.max_lines_count - 1
  CWindow.log(INVITE % {first:first_line, last:last_line})
  CWindow.textWind.clear
  2.times { CWindow.textWind.write(classe.blank_line + RC, CWindow::TEXT_COLOR) }
  page = (first_line..last_line).each do |iline|
    line = LEFT_MARGIN + (lines[iline]||SPACE).ljust(LINE_WIDTH) + RIGHT_MARGIN
    CWindow.textWind.write(line + RC, CWindow::TEXT_COLOR)
  end
  2.times { CWindow.textWind.write(classe.blank_line + RC, CWindow::TEXT_COLOR) }
end #/ show_lines

# Toutes les lignes du texte à afficher
def lines
  @lines ||= text.split(RC)
end #/ lines

# Le nombre de lignes (pour savoir si on atteint la fin)
def lines_count
  @lines_count ||= lines.count
end #/ lines_count

private

  def classe
    @classe ||= self.class
  end #/ classe

end #/Help
