#!/usr/bin/env ruby
# encoding: UTF-8
require 'curses'
# include Curses (pour éviter de répéter Curses)

Curses.init_screen
Curses.curs_set(0)  # Invisible cursor
Curses.start_color # pour la couleur

# Pour définir une couleur
Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_BLUE)

begin
  nb_lines  = Curses.lines
  nb_cols   = Curses.cols

  # Pour créer une fenêtre
  h, w, t, l = [10, 30, 2, 2]
  win1 = Curses::Window.new(h,w,t,l)
  win1.box(' ',' ')
  win1.setpos(3,3)
  win1.addstr("Salut toi !")
  win1.refresh
  win1.getch

  # On définit les attributs du prochain texte
  Curses.attrset(Curses.color_pair(2))

  # Pour placer le curseur
  x = nb_lines / 2
  y = nb_cols / 2
  Curses.setpos(x, y)

  # On écrit le texte (avec les précédents attributs définis)
  Curses.addstr("Salut tout le monde !")

  Curses.refresh

  Curses.getch

ensure
  Curses.close_screen
end

puts "Number of rows: #{nb_lines}"
puts "Number of columns: #{nb_cols}"
