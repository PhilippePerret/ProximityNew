# encoding: UTF-8
=begin
  Constantes proximites
=end

DISTANCE_MINIMALE_COMMUNE = 1000

# === Mots dont il faut ignorer les proximités ===
# Note : ne pas mettre les mots de moins de 4 lettres, qui sont exclus
# par défaut.
MOTS_SANS_PROXIMITES = {
  'elle'  => true,
  'il'    => true,
}

MOTS_APOSTROPHE = {
  'aujourd\'hui'.freeze => true,
  'prud\'hommes'.freeze => true,
  'd\'abord'.freeze => true,
  'd\'après'.freeze => true,
  'quelqu\'un'.freeze => true,
  'd\'ailleurs'.freeze => true,
  'd\'autant'.freeze => true,
  'd\'accord'.freeze => true,
}

MOTS_TIRET = {
  '--' => true,
  'à-coup' => true,
  'à-propos' => true,
  'après-midi' => true,
  'arrière-grand-père'  => true,
  'arrière-grand-papa'  => true,
  'arrière-grand-mère'  => true,
  'arrière-grand-maman' => true,
  'c\'est-à-dire' => true,
  'chez-soi'      => true,
  'chou-fleur'    => true,
  'coq-à-l\'âne'  => true,
  'franc-maçon'   => true,
  'grand-chose'   => true,
  'grand-père'    => true,
  'grand-papa'    => true,
  'grand-mère'    => true,
  'grand-maman'   => true,
  'gratte-ciel' => true,
  'laissez-passer'  => true,
  'non-dit' => true,
  'ouvre-boîte' => true,
  'ouvre-boite' => true,
  'peut-être'     => true,
  'pousse-café' => true,
  'porte-clés' => true,
  # 'qu\'en-dira-t-on' => true, Inconnu de tree-tagger
  'qualité-prix' => true,
  'rendez-vous' => true,
  'rouge-gorge' => true,
  'sage-femme' => true,
  'sans-gêne' => true,
  'saut-de-lit' => true,
  'sauve-qui-peut' => true,
  'tape-à-l\'œil' => true,
  'tout-à-l\'égout' => true,
  'train-train' => true,
  'va-et-vient' => true,
  'va-nu-pied' => true,
}

# Les transformables sont des expressions particulières que tree-tagger traite
# de façon particulière.
TRANSFORMABLES = {
  # Inconnu de tree-tagger mais qu'il faut transformer
  'qu\'en-dira-t-on' => ['qu\'', 'en-dira', '-t-on'], # BUG TreeTagger
  'est-ce' => ['est', '-ce'],
  'soi-même' => ['soi', '-même'],
  'qu\'eux-mêmes' => ['qu\'', 'eux', '-mêmes'],   # BUG TreeTagger
  'd\'eux-mêmes' => ['d\'', 'eux', '-mêmes'],     # BUG TreeTagger
  'qu\'elle-même' => ['qu\'', 'elle', '-même'],   # BUG TreeTagger
  'd\'elle-même' => ['d\'', 'elle', '-même'],     # BUG TreeTagger
  'qu\'elles-mêmes' => ['qu\'', 'elles', '-mêmes'],   # BUG TreeTagger
  'd\'elles-mêmes'  => ['d\'', 'elles', '-mêmes'],     # BUG TreeTagger
}

LOCUTIONS = {
  # loc:  La locution auquel peut appartenir le mot. Si elle est trouvée,
  #       aucun proximité n'est signalée.
  # req:  Indique les différentes manière de prendre les mots autour pour
  #       obtenir la locution. Chaque paire indique en premier le nombre de
  #       mots qu'il faut prendre avant (nil si aucun) et le nombre de mots
  #       qu'il faut prendre après. Si la locution contient 2 fois le mot, il
  #       doit y avoir 2 paires. Il doit y avoir autant de paires que de mots
  #       répétés dans la locution.
  #       Par exemple, [-1, 2] signifie qu'il faut prendre le
  #       mot avant et les deux mots suivants, tandis que [-3,nil] signifie
  #       qu'il faut prendre les 3 mots avant et aucun mot après.
  #
  # Toutes les locutions avec le mot "temps"
  'temps' => {loc:'de temps en temps', req: [[1,2], [3,nil]]},
  'coûte' => {loc:'coûte que coûte', req: [[nil,2], [3,nil]]},
  'plus'  => {loc:'de plus en plus', req:[[1,2], [3, nil]]},
  'moins'  => {loc:'de moins en moins', req:[[1,2], [3, nil]]},
  'côte'  => {loc:'côte à côte', req:[[nil,2], [2, nil]]},
}
