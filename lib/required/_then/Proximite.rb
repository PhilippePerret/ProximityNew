# encoding: UTF-8
=begin
  Class Proximite
=end
class Proximite
attr_reader :mot_avant, :mot_apres, :distance
def initialize(data)
  @mot_avant  = data[:avant]
  @mot_apres  = data[:apres]
  @distance   = data[:distance]
end #/ initialize

# Indice couleur en fonction de la distance. Plus elle est élevée, plus
# la couleur est "douce" (de vert, bleu, orange et rouge)
def color
  if    pourcentage_distance > 75 then CWindow::GREEN_COLOR
  elsif pourcentage_distance > 50 then CWindow::BLUE_COLOR
  elsif pourcentage_distance > 25 then CWindow::ORANGE_COLOR
  else CWindow::RED_COLOR
  end
end #/ color

# Renvoie le pourcentage de distance par rapport à la distance minimale.
# Rappel : cette distance peut varier d'un canon à l'autre
# Exemples :
#   Distance minimale     Distance
#       100                 50            0.5     50 %
# =>    100                 20
def pourcentage_distance
  100 * (distance / mot_avant.icanon.distance_minimale.to_f)
end #/ pourcentage_distance
end #/Proximite
