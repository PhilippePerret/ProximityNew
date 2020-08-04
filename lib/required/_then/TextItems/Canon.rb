# encoding: UTF-8
class Canon
class << self
  attr_accessor :items_as_hash
  def init
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
end #/ add

def count
  @items.count
end #/ count

# Pour actualiser le canon, c'est-à-dire mettre dans l'ordre ses
# items et ses offsets
def update
  @items.sort_by(&:offset)
  @offsets = @items.collect{|i|i.offset}
end #/ update

# Appelé pour le moment uniquement quand on change la distance minimale pour
# le texte
def reset
  @distance_minimale = nil
end #/ reset

def distance_minimale
  @distance_minimale ||= Runner.itexte.distance_minimale_commune
end #/ distance_minimale

end #/Canon
