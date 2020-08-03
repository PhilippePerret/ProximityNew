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
class << self
  attr_reader :textWind, :statusWind, :uiWind, :logWind
  attr_reader :top_ligne_texte_max
  def prepare_windows
    Curses.init_screen
    Curses.curs_set(0)  # Invisible cursor
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
    Curses.init_pair(ORANGE_COLOR,  Curses::COLOR_ORANGE, Curses::COLOR_WHITE)
    Curses.init_pair(BLUE_COLOR,    Curses::COLOR_BLUE,   Curses::COLOR_WHITE)
    Curses.init_pair(GREEN_COLOR,   Curses::COLOR_BLUE,   Curses::COLOR_WHITE)

    hauteur_log     = 2
    hauteur_status  = 2
    hauteur_ui      = 1
    hauteur_texte   = Curses.lines - (hauteur_status + hauteur_ui + hauteur_log)

    @textWind   = new([hauteur_texte, Curses.cols-2, 0,0])
    @logWind    = new([hauteur_log,   Curses.cols, hauteur_texte, 0])
    @statusWind = new([hauteur_status, Curses.cols, hauteur_texte+hauteur_log,0])
    @uiWind     = new([hauteur_ui,    Curses.cols, hauteur_texte+hauteur_log+hauteur_status, 0])

    @top_ligne_texte_max = hauteur_texte - 1

    # @textWind   = create(WindParams.new(hauteur_texte,0))
    # @statusWind = create(WindParams.new(hauteur_status, hauteur_texte))
    # @uiWind     = create(WindParams.new(hauteur_ui, hauteur_texte))
  end #/ prepare_windows

  # Pour écrire dans la fenêtre de log
  def log(str)
    @logWind.resetpos
    @logWind.write(str)
  end #/ log

  # Pour écrire une erreur
  def error(msg)
    @logWind.reset
    @logWind.write(msg,RED_ON_BLACK_COLOR)
  end #/ error

  def status(msg)
    @statusWind.reset
    @statusWind.write(msg+RC, BLUE_COLOR)
  end #/ status

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
  curse.attrset(Curses.color_pair(color)) unless color.nil?
  curse.addstr(str)
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
end #/CWindow
