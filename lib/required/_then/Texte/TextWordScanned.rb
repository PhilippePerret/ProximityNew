# encoding: UTF-8
=begin
  Class TextWordScanned
  ---------------------
  Classe "provisoire" qui permet, au mmoment du parsing du texte, d'analyser
  les mots.

  Dans le cas le plus simple, c'est un mot simple qui est envoyé à l'instancia-
  tion. Par exemple "jour". Avec derrière une espace ou une ponctuation.
  Dans ce cas, on retourne simplement une instance Mot et une instance NonMot.

  Les choses se compliquent lorsque :
    * le mot contient des apostrophes et/ou des traits d'union
    * le mot comporte une marque de style provenant de Scrivener

  Dans ce cas, il faut faire une étude du mot pour savoir si c'est quand
  même un mot simple (comme "aujourd'hui" ou "peut-être") ou s'il doit être
  décomposé en plusieurs mots comme dans "qu'on n'emmène pas les enfants"
  avec "qu'on" et "n'emmène".

TRAITEMENT DES MARQUES SCRIVENER
--------------------------------
  [1] La marque XSCRIVSTART ou XSCRIVEND est collé à un mot pour indiquer
      dans le fichier original la présence de <$Scriv_Cs::...> ou de
      <!$Scriv_Cs::...> (les '...' sont remplacés par des chiffres) qui sont
      des marques de style pour Scrivener.
      Ces marques sont collées au mot pour que le mot soit considéré avec sa
      marque, pour qu'on sache qu'il contient le début ou la fin d'un style.
      Noter qu'un non mot, par définition, ne peut pas contenir de marque
      puisque cette marque est justement un mot (avec chiffre).
  [2] La marque peut être seule, lorsqu'elle est entourée de non mots, comme
      c'est le cas par exemple à la fin d'une phrase. Dans ce cas, cette
      marque est associée au non-mot (indiquée dans son instance) et seul ce
      non-mot sera retourné.

TRAITEMENT DES APOSTROPHES ET TRAITS D'UNION
--------------------------------------------
  Avant, on regardait si le mot contenait des apostrophes et on le traitait
  ensuite s'il contenait des tirets et on le traitait. Mais ça posait plein
  de problèmes. Par exemple lorsque "to'tue" (pour "tortue") se trouvait dans
  "to'tue-té" (le "-té" était ajouté dans Le Parc pour parler d'une évolution
  de l'animal, ici la tortue). Donc en passant par cette méthode le mot
  "to'tue-té" n'existant pas au premier parsing, le programme découpait en
  "to'" et "tue-té" puis plus tard en "tue" et "té".
  Alors qu'il aurait dû chercher "to'tue" et "tue-té" avant tout

[4] Une des difficultés avec les apostrophes vient du fait qu'il faut séparer
    les mots en plusieurs instances mais les garder liés pour le fichier qui
    doit être lemmatisé. Par exemple, "c'est" doit produire ici deux mots
    distincts, "c'" et "est" mais ne doit pas être écrit "c' est" dans le
    fichier pour la lemmatisation car tree-tagger ne comprendrait pas et
    prendrait "c'" pour un mot inconnu.
    Il y a seulement le cas où l'apostrophe est à la fin qu'on ne doit pas
    coller le mot au suivant.

    DIFFICULTÉ DES TIRETS
    ---------------------
    Avec les tirets, la difficulté vient des mots qu'on compose avec eux,
    par exemple les nombres, qu'on ne peut pas tous énumérer dans une liste.

    Il faut aussi étudier les formes plurielles.

[5] Les fins telles que "-t-il" dans "parle-t-il" par exemple sont traitées
    comme deux mots par tree-tagger (-> "parle", "-t-il")

[6] Envoyer un string vide à la méthode `traite_string` peut survenir
    lorsqu'on a un string qui se termine par une apostrophe ou un tiret.
    Dans ce cas, le mot transmis se retrouve découpé en deux, avec un
    second élément vide.
    Ça arrive aussi, de la même manière, lorsque le mot commence par un
    tiret ou une apostrophe, comme dans « 'ziva ! »

=end
class TextWordScanned

# Fin verbale, par exemple pour "parle-t-on"
FIN_VERBALE = /((?:\-t)?\-(?:on|ils|il|elles|elle))$/i.freeze

# FIN_VERBALE = /(-(?:on|ils|il|elles|elle))$/i.freeze

FIN_DEMONSTRATIVE = /(\-(?:là|ci))/i.freeze

# Début pronominal, par exemple pour "qu'en penser" ou "d'aujourd'hui"
DEBUT_PRONOMINAL = /^((?:qu|d|t|m|s|n|l)')/i.freeze

attr_reader :mot, :nonmot
def initialize(mot, nonmot)
  @mot = mot
  @nonmot = nonmot
end #/ initialize

def scan
  # On traite très rapidement le cas le plus simple (le mot ne contient
  # ni apostrophe, ni trait d'union, ni marque de style ou autres éléments
  # qui pourrait constituer une marque)
  return [Mot.new(mot), NonMot.new(nonmot)] if mot_simple?

  # On traite le cas où le mot contient une marque scrivener. Dans ce
  # cas, on doit séparer cette marque du mot pour obtenir vraiment le mot
  # Le mot sera analysé seulement à ce moment-là
  if marque_scrivener?
    separe_mot_et_marque
    # Si la marque était seule, on peut tout de suite retourner seulement
    # le non-mot avec la marque.
    return [instance_nonmot_seule] if mot.nil?
    # Si on se trouve en présence d'un mot simple, on peut finaliser le
    # tout et le renvoyer.
    return [instance_mot, instance_nonmot] unless mot.match?(REG_APO_OR_TIRET)
    # Sinon, on poursuit
  end

  # À partir d'ici, on a un mot sans marque mais qui contient forcément
  # un ou des apostrophes et un ou des traits d'union.
  # On traite d'abord les cas simples puis on passera aux cas complexes
  # seulement en cas d'absolu nécessité.
  # [3] Chacune de ces méthodes doit renvoyer la liste des instances mots
  #     créées à laquelle on ajoute pour finir l'instance non-mot.

  titems = traite_string(mot)

  # Pour les éventuelles marques Scrivener
  titems[0].tap do |i|
    i.mark_scrivener_start  = @mark_style_start
    i.mark_scrivener_end    = @mark_style_end
  end

  titems << instance_nonmot # [3]

  # Liste finale renvoyée
  return titems
rescue Exception => e
  erreur("ERROR avec #{self.inspect}")
  erreur(e)
end #/ scan


# ---------------------------------------------------------------------
#   Méthodes de fabrication d'instances
# ---------------------------------------------------------------------

# @Params
#   foo   Soit un String (pour faire une instance collée de Mot)
#         Soit un Mot (qu'il suffit de marquer collé)
#         Soit un Array d'instances Mot qu'il faut tous coller
#
# @Return Quand on envoie une liste (Array) on retourne une liste,
# sinon on renvoie une instance Mot.
def instance_colled(foo)
  if foo.is_a?(Array)
    foo.each { |titem| titem.is_colled = true }
    return foo
  else
    foo = Mot.new(foo) if foo.is_a?(String)
    foo.tap { |i| i.is_colled = true }
    return foo # pour la clarté
  end
end #/ instance_colled

def instance_mot
  Mot.new(mot).tap do |i|
    i.mark_scrivener_start  = @mark_style_start
    i.mark_scrivener_end    = @mark_style_end
  end
end #/ instance_mot

def downcase
  @downcase ||= mot.downcase
end #/ downcase

def instance_nonmot
  @instance_nonmot ||= NonMot.new(nonmot)
end #/ instance_nonmot

# On compose une instance nonmot "seule" lorsque le mot se résumait
# à une marque de style Scrivener. Dans ce cas, c'est le non-mot qui
# porte cette marque dans son instance.
def instance_nonmot_seule
  instance_nonmot.tap do |i|
    i.mark_scrivener_start  = @mark_style_start
    i.mark_scrivener_end    = @mark_style_end
  end
end #/ instance_non_mot

# ---------------------------------------------------------------------
#   Méthodes opérationnelles
# ---------------------------------------------------------------------

def separe_mot_et_marque
  if mot.start_with?('XSCRIVSTART')
    # Cf. [1]
    @mark_style_start = mot[11...14].gsub(/O/,'').to_i
    @mot = mot[14..-1]
    @mot = nil if @mot.empty? # Cf. [2]
  elsif mot.start_with?('XSCRIVEND')
    @mark_style_end = mot[9...12].gsub(/O/,'').to_i
    @mot = mot[12..-1]
    @mot = nil if @mot.empty? # Cf. [2]
  end
end #/ separe_mot_et_marque


# La méthode de traitement, hors traitement du mot simple de départ et
# du traitement des marques Scrivener
# @Return une LISTE ARRAY des instances de mots créées (sans le NonMot de
# fin)
def traite_string(str)
  # log("-> traite_string(#{str.inspect})")
  if str.nil? # [6]
    [ ]
  elsif str.match?(REG_APO_OR_TIRET).nil? # un mot sans apostrophe ni tiret
    [ Mot.new(str) ]
  elsif mot_apostrophe_connu?(str)
    [ Mot.new(str) ]
  elsif mot_tiret_connu?(str)
    [ Mot.new(str) ]
  elsif transformable?
    TRANSFORMABLES[downcase].collect { |m| Mot.new(mt) }
  else # apostrophes + tirets
    scan_as_mot_complexe(str)
  end
end #/ traite_string

def scan_as_mot_complexe(str)
  # log("-> scan_as_mot_complexe(#{str.inspect})")

  # Traitement comme mot avec "fin verbale" [5]
  if str.match?(FIN_VERBALE)
    # log("#{str.inspect}.split(FIN_VERBALE) : #{str.split(FIN_VERBALE).inspect}")
    mot1, mot2 = str.split(FIN_VERBALE)
    return instance_colled(traite_string(mot1)) << Mot.new(mot2)
  end

  if str.match?(FIN_DEMONSTRATIVE)
    mot1, mot2 = str.split(FIN_DEMONSTRATIVE)
    return instance_colled(traite_string(mot1)) << Mot.new(mot2)
  end

  if str.match?(DEBUT_PRONOMINAL)
    vide, pronom, mot2 = str.split(DEBUT_PRONOMINAL)
    return [ instance_colled(pronom) ] + traite_string(mot2)
  end

  # Si le mot ne répond à aucun des cas précédents, on doit le
  # retourner tel quel
  return [ Mot.new(str) ]

end #/ scan_as_mot_complexe

# ---------------------------------------------------------------------
#   Méthodes de statut
# ---------------------------------------------------------------------

def mot_simple?
  return false if mot.match?(REG_APO_OR_TIRET)
  return false if marque_scrivener?
  return true
end #/ mot_simple?

def marque_scrivener?
  @has_mark_scrivener = mot.start_with?(/^(XSCRIVSTART|XSCRIVEND)/) if @has_mark_scrivener.nil?
  @has_mark_scrivener
end #/ marque_scrivener?

def transformable?
  @is_transformable = TRANSFORMABLES.key?(downcase) if @is_transformable.nil?
  @is_transformable
end #/ transformable?

def mot_apostrophe_connu?(str = nil)
  strd = (str || mot).downcase
  !!(MOTS_APOSTROPHE[strd] || Runner.itexte.liste_mots_apostrophe[strd])
end #/ mot_apostrophe_connu?

def mot_tiret_connu?(str = nil)
  strd = (str || mot).downcase
  !!(MOTS_TIRET[strd] || Runner.itexte.liste_mots_tiret[strd])
end #/ mot_tiret_connu?

end #/TextWordScanned
