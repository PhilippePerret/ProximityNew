# encoding: UTF-8
=begin
  Constantes proximites
=end

DISTANCE_MINIMALE_COMMUNE = 1000

MOTS_APOSTROPHE = {
  'aujourd\'hui'.freeze => true,
  'prud\'hommes'.freeze => true,
  'd\'abord'.freeze => true,
  'quelqu\'un'.freeze => true,
}

MOTS_TIRETS = {
  'peut-être'     => true,
  'grand-chose'   => true,
  'grand-père'    => true,
  'grand-papa'    => true,
  'grand-mère'    => true,
  'grand-maman'   => true,
  'arrière-grand-père'  => true,
  'arrière-grand-papa'  => true,
  'arrière-grand-mère'  => true,
  'arrière-grand-maman' => true,
}

LOCUTIONS = {
  # loc:  La locution auquel peut appartenir le mot. Si elle est trouvée,
  #       aucun proximité n'est signalée.
  # req:  Indique comment il faut prendre les mots autour pour obtenir la
  #       locution. Par exemple, [-1, 2] signifie qu'il faut prendre le
  #       mot avant et les deux mots suivants, tandis que [-3,nil] signifie
  #       qu'il faut prendre les 3 mots avant et aucun mot après.
  #
  # Toutes les locutions avec le mot "temps"
  'temps' => {loc:'de temps en temps', req: [[-1,2], [-3,nil]]},
}
