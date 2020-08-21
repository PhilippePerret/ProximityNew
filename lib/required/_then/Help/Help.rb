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
  {titre:'Navigation dans le texte', file:'navigation'},
  {titre:'Parsing', file:'parsing_text'},
  {titre:'Modification du texte', file:'modify_text'},
  {titre:'Reconstruction du texte', file:'rebuilding_text'},
  {titre:'Définition des constantes de proximités', file:'define_constantes'},
  {titre:'Listes spéciales', file:'special_lists'},
  {titre:'Annexe : autres commandes', file:'other_commands'},
  {titre:'Annexe : les index', file:'index'},
  {titre:'Annexe : les modes de clavier', file:'modes_claviers'},
  {titre:'Fin de l’aide', file:'fin'},
]

TDM_DEVELOPPER = [
  {titre:'Introduction au développement', file:'xdev/introduction'},
  {titre:'Principes généraux', file:'xdev/principes'},
  {titre:'Les Classes d’éléments', file:'xdev/classes'},
  {titre:'Utilisation de la base de données', file:'xdev/database'},
  {titre:'Modification d’un texte', file:'xdev/modify_text'},
  {titre:'Les Canons', file:'xdev/canons'},
  {titre:'Les Proximités', file:'xdev/proximites'},
  {titre:'Messagerie', file:'xdev/messages'},
  {titre:'Projets Scrivener', file:'xdev/scrivener'},
  {titre:'Annexe : réflexions', file:'xdev/reflexions'},
]

class << self
  # Pour savoir quelle aide utilisée, celle pour l'utilisateur ou celle
  # pour le développeur.
  attr_reader :tdm

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
    define_type_aide(suite_cmd) # utilisateur ou développeur
    define_current_aide(suite_cmd.shift)
    current.output
    interact
    on_quit
  end #/ show

  def define_type_aide(suite_cmd)
    for_developper = ['--dev', '-d'].include?(suite_cmd[0])
    @tdm = for_developper ? TDM_DEVELOPPER : TDM
    suite_cmd.pop if for_developper
  end #/ define_type_aide

  # Méthode qui définit, au début de l'aide, le fichier d'aide à utiliser et
  # son index. Quand on parle de fichier d'aide ici, on parle de fichier dans
  # le dossier Help/textes (ou Help/textes/xdev pour l'aide au développement)
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
      tdm.each do |daide, idx_aide|
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
    @current = new(tdm[@aide_index])
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
    next_data = tdm[aide_index + 1]
    log("next_data: #{next_data.inspect}",true)
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
      @current = new(tdm[@aide_index -= 1])
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
  @last_line  = first_line + classe.max_lines_count - 1
  # Si les lignes ne sont pas encore traitées, il faut le faire
  formate_lines if not @lines_has_been_formated
  # sait pas combien de lignes contient a priori un fichier.
  CWindow.textWind.clear
  2.times { CWindow.textWind.write(classe.blank_line + RC, CWindow::TEXT_COLOR) }
  (first_line..last_line).each do |iline|
    @formated_lines[iline].each do |aline|
      aline.each do |data_segment|
        CWindow.textWind.write(*data_segment)
      end
    end
  end
  2.times { CWindow.textWind.write(classe.blank_line + RC, CWindow::TEXT_COLOR) }
  CWindow.log(INVITE % {first:first_line, last:last_line})
end #/ show_lines

# Formatage des lignes du fichier d'aide courant
def formate_lines
  @formated_lines = []
  lines.each do |line|
    @formated_lines = segments_line_traited(line, @formated_lines)
  end
  @lines_has_been_formated = true
end #/ formate_lines
# @Reçoit la ligne d'aide +rawline+ (qui pourrait s'appeler +mdline+ aussi
# puisqu'elle est en markdown)
# @Return les textes à écrire dans CWindow.textWind avec Curses, qu'on appelle
# des "segments". Chaque segment doit définir son contenu textuel et son
# style ou sa couleur.
# @Params
#   +flines+ {Array} Les lignes actuelles de l'aide
def segments_line_traited(rawline, flines)
  segments = []
  # On commence par s'assurer que les lignes ne soient pas trop longues
  if rawline.length > LINE_WIDTH
    rawline = rawline.strip
    segstr = ""
    seglen = 0
    rawline.split(SPACE).each do |motstr|
      motstr += SPACE
      motlen = motstr.length
      if seglen + motlen > LINE_WIDTH
        segments << segstr
        segstr = ""
        seglen = 0
      end
      segstr << motstr
      seglen += motlen
    end
    # On ajoute la fin
    segments << segstr unless segstr.empty?
  else
    segments << rawline
  end
  # Ici, dans new_segments, il n'y a que des segments sans indentation et
  # sans retour charriot.
  new_segments = []
  segments.each_with_index do |segment, idx|
    if segment.start_with?('#')
      # Si c'est un titre
      segment = segment.strip
      level = nil
      segment.sub!(/^(#+) /){
        level = $1.length
        EMPTY_STRING
      }
      sign = level < 2 ? '='.freeze : TIRET
      soulignement = [LEFT_MARGIN + (sign * segment.length).ljust(LINE_WIDTH) + RIGHT_MARGIN + RC, CWindow::ORANGE_COLOR|Curses::A_BOLD]
      # On ajoute autant d'espace après que de dièses retirés
      segment = segment + SPACE * (level + 1)
      flines << [[LEFT_MARGIN + segment.upcase.ljust(LINE_WIDTH) + RIGHT_MARGIN + RC, CWindow::ORANGE_COLOR|Curses::A_BOLD]]
      flines << [soulignement]
    elsif segment.match?(/`(.+?)`/)
      segment = segment.strip
      segs = segment.split(/`(.+?)`/)
      line_len = 0
      new_segments << [LEFT_MARGIN, CWindow::TEXT_COLOR]
      if segs.first.empty?
        # Une ligne qui commence par du code
        segs.shift
        code = segs.shift
        new_segments << [code, CWindow::YELLOW_ON_DARK]
        line_len += code.length
      end
      segs.reverse!
      while seg = segs.pop
        new_segments << [seg, CWindow::TEXT_COLOR] # du code
        line_len += seg.length
        code = segs.pop
        unless code.nil?
          line_len += code.length
          new_segments << [code, CWindow::YELLOW_ON_DARK]
        end
      end
      if line_len < LINE_WIDTH
        new_segments << [SPACE * (LINE_WIDTH - line_len), CWindow::TEXT_COLOR]
      end
      new_segments << [RIGHT_MARGIN + RC, CWindow::TEXT_COLOR]
      flines << new_segments
    else
      flines << [[LEFT_MARGIN + segment.ljust(LINE_WIDTH) + RIGHT_MARGIN + RC, CWindow::TEXT_COLOR]]
    end
  end
  return flines
end #/ segments_line_traited

# Toutes les lignes du texte à afficher. Maintenant, elles peuvent être
# plus longues que l'affichage puisqu'elles seront découpées.
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
