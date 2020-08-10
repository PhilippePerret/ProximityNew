# encoding: UTF-8
=begin

  CWindow
  -------
  Classe pour une fenêtre curses
  Fondamentalement, il y en a trois pour Runner :
    1. La fenêtre affichant le texte et les proximités
    2. La fenêtre affichant le statut
    3. La fenêtre permettant d'entrer les commandes.

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
INDEX_COLOR   = 1
RED_COLOR     = 2
RED_ON_BLACK_COLOR = 7
TEXT_COLOR    = 3
ORANGE_COLOR  = 4
BLUE_COLOR    = 5
GREEN_COLOR   = 6
WHITE_ON_BLACK = 0

class << self
  attr_reader :textWind, :statusWind, :uiWind, :logWind
  attr_reader :top_ligne_texte_max
  attr_accessor :hauteur_texte

  HAUTEUR_LOG     = 4
  HAUTEUR_STATUS  = 1
  HAUTEUR_UI      = 1

  def init_curses
    Curses.init_screen
    # Curses.curs_set(0)  # Invisible cursor
    # Window.keypad(true) # pour que les clés soient Curses::KEY::RETURN
    # Curses.nodelay= false # getch doit attendre
    Curses.start_color # pour la couleur
    Curses.noecho

    Curses.init_color(Curses::COLOR_ORANGE, 1000, 128*4, 0)

    # Pour définir une couleur
    Curses.init_pair(INDEX_COLOR,   Curses::COLOR_YELLOW, Curses::COLOR_WHITE)
    Curses.init_pair(TEXT_COLOR,    Curses::COLOR_BLACK,  Curses::COLOR_WHITE)
    Curses.init_pair(RED_COLOR,     Curses::COLOR_RED,    Curses::COLOR_WHITE)
    Curses.init_pair(RED_ON_BLACK_COLOR, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(WHITE_ON_BLACK, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(ORANGE_COLOR,  Curses::COLOR_ORANGE, Curses::COLOR_WHITE)
    Curses.init_pair(BLUE_COLOR,    Curses::COLOR_BLUE,   Curses::COLOR_WHITE)
    Curses.init_pair(GREEN_COLOR,   Curses::COLOR_BLUE,   Curses::COLOR_WHITE)
  end #/ init_curses

  def prepare_windows

    init_curses

    deadLines = 0 # Pour essayer d'empêcher l'écran de sauter
    self.hauteur_texte   = Curses.lines - (HAUTEUR_STATUS + HAUTEUR_UI + HAUTEUR_LOG) - deadLines
    # La hauteur (de texte) à prendre en compte pour les autres fenêtres
    # que la fenêtre de texte.
    hTextRef = hauteur_texte + deadLines

    @textWind   = new([hauteur_texte, Curses.cols-2, 0,0])
    @logWind    = new([HAUTEUR_LOG,   Curses.cols, hTextRef, 0])
    @statusWind = new([HAUTEUR_STATUS, Curses.cols, hTextRef+HAUTEUR_LOG,0])
    @uiWind     = new([HAUTEUR_UI,    Curses.cols, hTextRef+HAUTEUR_LOG+HAUTEUR_STATUS, 0])

    @top_ligne_texte_max = hauteur_texte - 1

    # @textWind   = create(WindParams.new(hauteur_texte,0))
    # @statusWind = create(WindParams.new(HAUTEUR_STATUS, hauteur_texte))
    # @uiWind     = create(WindParams.new(HAUTEUR_UI, hauteur_texte))
  end #/ prepare_windows

  # Pour écrire dans la fenêtre de log
  def log(str)
    @logWind.resetpos
    @logWind.write(str)
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
  #
  def init_status_and_cursor(data_mode_clavier = nil)
    set_mode_clavier(data_mode_clavier)
    set_distance_minimale_defaut
    set_statut_extrait
    set_titre_texte
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
    str = " Items:#{Runner.iextrait.from_item}-#{Runner.iextrait.to_item}".freeze
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
  #               c'est toujours la fenêtre ui
  #   :message    Le message à afficher dans la fenêtre de log
  #   :keys       Une liste des touches admises, qui produira le retour
  #               de l'attente. Si non fournie, c'est qu'on attend un texte.
  #               Il sera retourné lorsque l'on pressera la touche entrée.
  def wait_for_user(params = nil)
    params ||= {}
    params[:window] ||= @uiWind
    logWind.write(params[:message])
    uiWind.clear
    uiWind.curse.setpos(uiWind.curse.cury, uiWind.curse.curx)
    choix = nil
    while true
      s = uiWind.curse.getch
      if params[:keys] && params[:keys].include?(s)
        choix = s
        break
      elsif s == 10 # touche entrée
        break
      elsif s == 127 # annulation
        choix = nil
        break
      else
        choix ||= ''
        choix << s.to_s
        uiWind.clear
        uiWind.write(choix)
      end
    end
    logWind.clear
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
  curse.setpos(0,0)
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
