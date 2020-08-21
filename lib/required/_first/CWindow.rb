# encoding: UTF-8
=begin

  CWindow
  -------
  Classe pour une fenêtre curses
  Fondamentalement, il y en a trois pour Runner :
    1. La fenêtre affichant le texte et les proximités
    2. La fenêtre affichant le statut
    3. La fenêtre permettant d'entrer les commandes.


  On peut trouver les 256 couleurs disponibles (pour former les paires avec
  init_pair) à l'adresse : https://jonasjacek.github.io/colors/
  Par exemple, un vrai blanc sur noir :
    Curses.init_pair(1, 0, 255)

=end
require 'curses'
WindParams = Struct.new(:height, :top)

Curses::COLOR_ORANGE = 5 # MAGENTA

class CWindow
# ---------------------------------------------------------------------
#
#   CLASSE
#
# ---------------------------------------------------------------------
WHITE_ON_BLACK = 0


TEXT_COLOR    = 100 # jusqu'à 256 compris
INDEX_COLOR   = 101 # idem
# Pour indiquer l'intensité des proximités
RED_COLOR     = 110
ORANGE_COLOR  = 111
BLUE_COLOR    = 112
GREEN_COLOR   = 113
RETURN_COLOR  = 114
RED_ON_BLACK_COLOR = 120 # En cas d'erreur
YELLOW_ON_DARK  = 140 # pour le code dans les fichiers d'aide

CWindow::BnW_BLACK = 0   # pur noir
CWindow::BnW_WHITE = 255  # pur blanc (plus blanc que 15)

class << self
  attr_reader :textWind, :statusWind, :uiWind, :logWind
  attr_reader :top_ligne_texte_max
  attr_reader :hauteur_texte

  HAUTEUR_LOG     = 4
  HAUTEUR_STATUS  = 1
  HAUTEUR_UI      = 1

  def init_curses
    Curses.init_screen
    Curses.start_color # pour la couleur
    Curses.use_default_colors
    # Curses.curs_set(0)  # Invisible cursor
    # Window.keypad(true) # pour que les clés soient Curses::KEY::RETURN
    # Curses.nodelay= false # getch doit attendre
    Curses.noecho


    # Pour définir une couleur
    Curses.init_pair(INDEX_COLOR,   Curses::COLOR_YELLOW, Curses::COLOR_WHITE)
    Curses.init_pair(TEXT_COLOR,    Curses::COLOR_BLACK,  Curses::COLOR_WHITE)
    Curses.init_pair(WHITE_ON_BLACK, Curses::COLOR_WHITE, Curses::COLOR_BLACK)

    # Texte
    Curses.init_pair(TEXT_COLOR,        CWindow::BnW_BLACK, 255) #Curses::BnW_WHITE
    Curses.init_pair(INDEX_COLOR, 251,  CWindow::BnW_WHITE)
    Curses.init_pair(RETURN_COLOR, 88, 159)
    # Proximités
    Curses.init_pair(RED_COLOR,     196,    CWindow::BnW_WHITE)
    Curses.init_pair(ORANGE_COLOR,  214,    CWindow::BnW_WHITE) # 208
    Curses.init_pair(BLUE_COLOR,    Curses::COLOR_BLUE,   CWindow::BnW_WHITE)
    Curses.init_pair(GREEN_COLOR,   112,   CWindow::BnW_WHITE) # 70, 76
    # Messages
    Curses.init_pair(RED_ON_BLACK_COLOR, 196, CWindow::BnW_BLACK)
    Curses.init_pair(YELLOW_ON_DARK, 11, 28)

  end #/ init_curses

  def prepare_windows

    init_curses

    # La hauteur (de texte) à prendre en compte pour les autres fenêtres
    # que la fenêtre de texte.
    hTextRef = @hauteur_texte = (Curses.lines - (HAUTEUR_STATUS + HAUTEUR_UI + HAUTEUR_LOG)).freeze

    @textWind   = new([hauteur_texte,   Curses.cols-2, 0,0])
    @logWind    = new([HAUTEUR_LOG,     Curses.cols, hTextRef, 0])
    @statusWind = new([HAUTEUR_STATUS,  Curses.cols, hTextRef+HAUTEUR_LOG,0])
    @uiWind     = new([HAUTEUR_UI,      Curses.cols, hTextRef+HAUTEUR_LOG+HAUTEUR_STATUS, 0])

    @top_ligne_texte_max = hauteur_texte - 1

    # @textWind   = create(WindParams.new(hauteur_texte,0))
    # @statusWind = create(WindParams.new(HAUTEUR_STATUS, hauteur_texte))
    # @uiWind     = create(WindParams.new(HAUTEUR_UI, hauteur_texte))
  end #/ prepare_windows

  # Pour écrire dans la fenêtre de log
  def log(str, options = nil)
    options ||= {}
    if options.key?(:pos)
      if options[:pos] == :keep
        # On reste à la même place
      else # sinon, on se place à l'endroit voulu
        @logWind.setpos(options[:pos])
      end
    else
      @logWind.resetpos
    end
    @logWind.write(str, options[:color]||options[:couleur])
    init_status_and_cursor
  end #/ log

  # Pour écrire une erreur
  def error(msg)
    @logWind.reset
    @logWind.write(msg,RED_ON_BLACK_COLOR)
    init_status_and_cursor
  end #/ error

  # *** Fenêtre statut ***

  colonne_cur = 0
  MODE_CLAVIER_START = colonne_cur   # colonne de départ pour l'affichage du mode clavier
  MODE_CLAVIER_WIDTH = 14
  colonne_cur += MODE_CLAVIER_WIDTH
  DIST_MINIMAL_START = colonne_cur
  DIST_MINIMAL_WIDTH = 11
  colonne_cur += DIST_MINIMAL_WIDTH
  EXTRAIT_INFOS_START = colonne_cur
  EXTRAIT_INFOS_WIDTH = 19  # p.e. "Mots: 400000-410000"
  colonne_cur += EXTRAIT_INFOS_WIDTH
  MSG_STATUT_START = colonne_cur
  MSG_STATUT_WIDTH = 30
  colonne_cur += MSG_STATUT_WIDTH

  TITRE_TEXTE_WIDTH = 30
  TITRE_TEXTE_START = Curses.cols - TITRE_TEXTE_WIDTH

  # = main =
  #
  # Méthode principale qui actualise le statut affiché.
  # La méthode place également le curseur au bon endroit et nettoie
  # la fenêtre log si options[:clear] est true.
  #
  def init_status_and_cursor(params = nil)
    params ||= {}
    set_mode_clavier(params[:mode_clavier])
    set_distance_minimale_defaut
    set_statut_extrait
    set_titre_texte
    logWind.clear if params[:clear]
    # Pour remettre le curseur au bon endroit
    uiWind.curse.setpos(uiWind.curse.cury, uiWind.curse.curx)
  end #/ init_status_and_cursor

  def status(msg)
    @statusWind.reset
    @statusWind.writepos([0, MSG_STATUT_START], msg.ljust(MSG_STATUT_WIDTH), BLUE_COLOR)
    init_status_and_cursor
  end #/ status

  def set_titre_texte
    titre = Runner.itexte.nil? ? '---' : Runner.itexte.fname
    titre = if titre.length > TITRE_TEXTE_WIDTH - 1
      titre_av = titre[0...(TITRE_TEXTE_WIDTH/2 - 1)]
      titre_ap = titre[(TITRE_TEXTE_WIDTH/2 - 1)..-1]
      " #{titre_av}…#{titre_ap}".freeze
    else
      titre.rjust(TITRE_TEXTE_WIDTH - 1)
    end + SPACE
    @statusWind.writepos([0,TITRE_TEXTE_START,TITRE_TEXTE_WIDTH], titre, TEXT_COLOR)
  end #/ set_titre_texte

  def set_statut_extrait
    unless Runner.instance_variable_get("@iextrait").nil?
      str = " Items:#{Runner.iextrait.from_item}-#{Runner.iextrait.to_item}".freeze
    else
      str = '---'
    end
    @statusWind.writepos([0,EXTRAIT_INFOS_START,EXTRAIT_INFOS_WIDTH], str, TEXT_COLOR)
  end #/ set_statut_extrait

  def set_mode_clavier(adata = nil)
    adata ||= ['NORMAL', CWindow::TEXT_COLOR]
    str, color = adata
    str.prepend(" Clav:".freeze)
    @statusWind.writepos([0, MODE_CLAVIER_START, MODE_CLAVIER_WIDTH], str, color)
    # init_status_and_cursor # NON ! SINON BOUCLE
  end #/ set_mode_clavier
  def set_distance_minimale_defaut(valeur = nil)
    valeur ||= Runner.itexte.distance_minimale_commune
    valeur = valeur.to_s
    valeur.prepend('Dist:')
    @statusWind.writepos([0,DIST_MINIMAL_START,DIST_MINIMAL_WIDTH], valeur, TEXT_COLOR)
  end #/ set_distance_minimale_defaut

  # Permet d'attendre une touche de l'utilisateur
  # +params+
  #   :window     La fenêtre dans laquelle le cursor doit attendre. Par défaut
  #               c'est la fenêtre ui
  #   :message    Le message à afficher dans la fenêtre de log
  #   :keys       Une liste des touches admises, qui produira le retour
  #               de l'attente. Si non fournie, c'est qu'on attend un texte.
  #               Il sera retourné lorsque l'on pressera la touche entrée.
  def wait_for_user(params = nil)
    params ||= {}
    params[:window] ||= @uiWind
    if params[:message]
      logWind.clear
      logWind.write(params[:message])
    end
    uiWind.clear
    uiWind.curse.setpos(uiWind.curse.cury, uiWind.curse.curx)
    choix = nil
    while true
      s = uiWind.curse.getch
      if params[:keys] && params[:keys].include?(s)
        choix = s
        break
      elsif s == 127 # annulation
        choix = nil
        break
      elsif params[:keys]
        uiWind.clear
        # Si 258 => flèche bas, 259 => flèche haut
        uiWind.write("Il faut choisir une lettre parmi : #{params[:keys].join(VGE)}.".freeze)
      else
        choix ||= ''
        choix << s.to_s
        uiWind.clear
        uiWind.write(choix)
      end
    end
    # logWind.clear
    uiWind.curse.setpos(uiWind.curse.cury, uiWind.curse.curx)
    return choix
  end #/ wait_for_user

end #/<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :curse
def initialize(params)
  @curse = Curses.stdscr.subwin(*params)
  # @curse.box(SPACE,SPACE) # pour voir des "hirondelles" (pour réglage)
  @curse.keypad = true
end #/ initialize
def write(str, color = nil)
  if color.nil?
    curse.addstr(str.to_s)
  else
    curse.attron(Curses.color_pair(color)) { curse.addstr(str.to_s) }
  end
  curse.refresh
end #/ puts
def setpos(pos)
  curse.setpos(*pos)
end #/ setpos
def writepos(pos, str, color = nil)
  if pos.count == 3
    str_width = pos.pop
    str = str.ljust(str_width) unless str_width.nil?
  end
  curse.setpos(*pos)
  write(str, color)
end #/ writepos
def resetpos
  clear
  setpos([0,0])
end #/ resetpos
alias :reset :resetpos
def clear
  curse.clear
  curse.refresh
end #/ clear
def wait_for_char
  curse.getch.to_s
end #/ wait_for_char
end #/CWindow
