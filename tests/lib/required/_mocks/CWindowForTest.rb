# encoding: UTF-8
=begin
  Classe CWindowForTest
  ---------------------
  Pour remplacer les méthodes CWindow
=end
class CWindowForTest
  attr_reader :id
  attr_reader :lines
  def initialize(id)
    @id     = id # p.e. 'textWind' ou 'logWind'
    @lines  = []
  end #/ initialize
  # ---------------------------------------------------------------------
  #   Méthodes de tests
  #
  # Elles peuvent être utilisées avec ecran.contient, log.contient
  # status.contient
  # ---------------------------------------------------------------------
  def contient(ca, params = nil)
    puts "L’écran doit contenir #{ca}"
    if lines.join(RC).include?(ca)
      puts "IL CONTIENT"
    else
      puts "IL NE CONTIENT PAS"
      puts lines.join(RC)
    end
  end #/ content

  # ---------------------------------------------------------------------
  #   Méthodes de l'application surclassées
  # ---------------------------------------------------------------------
  def clear
    puts "Je nettoie la fenêtre #{id}"
    @lines = []
  end #/ clear
  def write(msg, color = nil)
    puts "J'écris #{msg.inspect} dans la fenêtre #{id} de la couleur #{color.inspect}"
    @lines = msg.split(RC)
  end #/ write
  def writepos(ary_pos, msg, color = nil)
    puts "J'écris #{msg.inspect} dans la fenêtre #{id} à #{ary_pos.inspect}#{" avec la couleur #{color}" unless color.nil?}"
    @lines = msg.split(RC)
    # TODO À remettre
    # if ary_pos[1] == 0
    #   @lines[ary_pos[0]] = msg
    # else
    #   @lines[ary_pos[0]] = @lines[ary_pos[0]][0...ary_pos[1]].ljust(ary_pos[1])
    #   @lines[ary_pos[0]] << msg
    # end
  end #/ writepos
  def interact_with_user
    # La méthode doit retourner le premier élément de CLAVIER en l'effaçant
    CLAVIER.shift
  end #/ interact_with_user
  # Normalement, curse est la fenêtre NCurses. Ici, c'est l'instance elle-même,
  # qui doit donc répondre aux mêmes méthodes.
  def curse
    self
  end #/ curse
  def getch
    CLAVIER.shift
  end #/ getch
end #/CWindowForTest
