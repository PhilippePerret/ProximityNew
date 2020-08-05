# encoding: UTF-8
=begin
  Test de l'aide
=end
require_relative '../lib/required'

def textWind
  CWindow.textWind.content
end #/ textWind

CLAVIER = ['q','q']
Runner.open_texte("/Users/philippeperret/Programmation/ProximityNew/asset/exemples/simple_text.txt")
run(':help')


if textWind.include?('AIDE')
  puts "La fenêtre contient AIDE"
else
  puts "La fenêtre devrait contenir AIDE"
end
