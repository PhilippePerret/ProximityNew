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

  HAUTEUR_LOG     = 3
  HAUTEUR_STATUS  = 2
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

    self.hauteur_texte   = Curses.lines - (HAUTEUR_STATUS + HAUTEUR_UI + HAUTEUR_LOG)

    @textWind   = new([hauteur_texte, Curses.cols-2, 0,0])
    @logWind    = new([HAUTEUR_LOG,   Curses.cols, hauteur_texte, 0])
    @statusWind = new([HAUTEUR_STATUS, Curses.cols, hauteur_texte+HAUTEUR_LOG,0])
    @uiWind     = new([HAUTEUR_UI,    Curses.cols, hauteur_texte+HAUTEUR_LOG+HAUTEUR_STATUS, 0])

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

  def status(msg)
    @statusWind.reset
    @statusWind.write(msg+RC, BLUE_COLOR)
    init_status_and_cursor
  end #/ status

  def set_mode_clavier(adata = nil)
    adata ||= ['  NORMAL  ', CWindow::TEXT_COLOR]
    @statusWind.writepos([0, 30], *adata)
    # init_status_and_cursor # NON ! SINON BOUCLE
  end #/ set_mode_clavier

  def init_status_and_cursor(data_mode_clavier = nil)
    set_mode_clavier(data_mode_clavier)
    uiWind.curse.setpos(uiWind.curse.cury, uiWind.curse.curx)
  end #/ init_status_and_cursor

end #/<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :curse
def initialize(params)
  @curse = Curses.stdscr.subwin(*params)
  @curse.box(SPACE,SPACE) # pour voir des "hirondelles"
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
end #/ clear
def wait_for_char
  curse.getch.to_s
end #/ wait_for_char
end #/CWindow
