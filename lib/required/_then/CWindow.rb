# encoding: UTF-8
=begin

  CWindow
  -------
  Classe pour une fenêtre curses
  Fondamentalement, il y en a trois pour ProximityNew :
    1. La fenêtre affichant le texte et les proximités
    2. La fenêtre affichant le statut
    3. La fenêtre permettant d'entrer les commandes.

=end
require 'curses'
WindParams = Struct.new(:height, :top)

class CWindow
# ---------------------------------------------------------------------
#
#   CLASSE
#
# ---------------------------------------------------------------------
class << self
  attr_reader :textWind, :statusWind, :uiWind, :logWind
  def prepare_windows
    Curses.init_screen
    Curses.curs_set(0)  # Invisible cursor
    # Window.keypad(true) # pour que les clés soient Curses::KEY::RETURN
    # Curses.nodelay= false # getch doit attendre
    Curses.start_color # pour la couleur
    Curses.noecho

    # Pour définir une couleur
    Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_BLUE)

    hauteur_status  = 2
    hauteur_ui      = 4
    hauteur_log     = 4
    hauteur_texte   = Curses.lines - (hauteur_status + hauteur_ui + hauteur_log)

    @textWind = new([hauteur_texte, Curses.cols-2, 1, 2])
    @uiWind   = new([hauteur_ui,    Curses.cols, hauteur_texte+hauteur_status, 0])
    @logWind  = new([hauteur_log,   Curses.cols, hauteur_texte+hauteur_status+hauteur_ui, 0])

    # @textWind   = create(WindParams.new(hauteur_texte,0))
    # @statusWind = create(WindParams.new(hauteur_status, hauteur_texte))
    # @uiWind     = create(WindParams.new(hauteur_ui, hauteur_texte))
  end #/ prepare_windows
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
def write(str)
  curse.addstr(str)
  curse.refresh
end #/ puts
def resetpos
  clear
  curse.setpos(1,1)
end #/ resetpos
def clear
  curse.clear
end #/ clear
def watch
  start_command = false
  command = nil
  while true
    case s = curse.getch
    when 27 # Escape button
      start_command = false
      command = ""
      clear
      write(EMPTY_STRING)
    when ':'
      start_command = true
      command = ""
      resetpos
      write(':')
    when 10
      case command
      when 'q'
        break
      else
        clear
        Commande.run(command)
        historize(command)
      end
    when 261 # RIGHT ARROW
      write("Aller à droite")
    when 260 # LEFT ARROW
      write("Aller à gauche")
    when 258 # BOTTOM ARROW
      write("Aller en bas")
    when 259 # TOP ARROW
      write("Aller en haut")
    when 127 # effacement arrière
      if start_command
        command = command[0...-1]
        clear
        write(":#{command}")
      end
    else
      if start_command && s.is_a?(String)
        command << s
      end
      write(s.to_s)
    end
  end
end #/ watch

# Mémoriser la commande dans l'historique de la fenêtre
def historize(command)
  @historique ||= []
  @historique << command
end #/ historize
end #/CWindow
