# encoding: UTF-8
class Canon
class << self
  attr_accessor :items_as_hash

  def init
    unless items_as_hash.nil?
      items_as_hash.each { |k, v| v = nil}
    end
    self.items_as_hash = {}
  end #/ init

  def each &block
    if block_given?
      items_as_hash.each do |c, ic|
        break if yield(ic) === false
      end
    end
  end #/ each

  # Ici, +mot+ est un mot qui ne connait pas encore son canon, il a juste
  # été enregistré dans Texte#items
  def add(mot, canon)
    canon = mot.content.downcase if canon == LEMMA_UNKNOWN
    unless self.items_as_hash.key?(canon)
      new_canon = new(canon)
      self.items_as_hash.merge!(canon => new_canon)
    end
    self.items_as_hash[canon].add(mot)
  end #/ add

  # Retire le mot +mot+ de son canon
  def remove(mot)
    mot.icanon.remove(mot)
  end #/ remove

  # Pour obtenir l'instance d'un canon par `Canon[canon]`
  # Pour le moment, cette méthode n'est utilisée que pour la nouvelle formule
  # qui fonctionne par extrait isolé.
  def [] canon
    @items_as_hash ||= {}
    @items_as_hash[canon] ||= new(canon)
  end #/

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :canon, :items, :offsets
def initialize(canon)
  @canon    = canon
  @items    = []
  @offsets  = []
end #/ initialize

# Ajout d'un mot au canon
def add(mot)
  mot.icanon = self
  mot.canon  = self.canon
  @items << mot
  @offsets << mot.offset unless mot.offset.nil?
end #/ add

def remove(mot)
  idx = items.find_index { |m| m.index == mot.index }
  unless idx.nil? # ça arrive quand on vient de retirer le mot par un autre biais
    items.slice!(idx)
    offsets.slice!(idx)
  end
end #/ remove

def count
  @items.count
end #/ count

# Pour actualiser le canon, c'est-à-dire mettre dans l'ordre ses
# items et ses offsets
def update
  @items.sort_by(&:offset)
  @offsets = @items.collect { |i| i.offset }
end #/ update

# Appelé pour le moment uniquement quand on change la distance minimale pour
# le texte
def reset
  @distance_minimale  = nil
  @is_canon_ignored   = nil
end #/ reset

def distance_minimale
  @distance_minimale ||= Runner.itexte.distance_minimale_commune
end #/ distance_minimale

# Retourne true si c'est un canon ignoré (soit par l'application soit par
# le texte en particulier). Il faut calculer la valeur une bonne fois pour
# toutes pour ne pas avoir à la recalculer pour chaque mot. Elle ne doit être
# resettée que lorsqu'on ajoute ou enlève un nouveau mot sans proximité
def ignored?
  @is_canon_ignored = Runner.itexte.prox_ignored_for?(canon) if @is_canon_ignored.nil?
  @is_canon_ignored
end #/ ignored?

end #/Canon
