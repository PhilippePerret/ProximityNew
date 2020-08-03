# encoding: UTF-8
class Canon
class << self
  attr_accessor :items_as_hash
  def init
    self.items_as_hash = {}
  end #/ init
  def add(mot)
    unless self.items_as_hash.key?(mot.canon)
      new_canon = new(mot.canon)
      self.items_as_hash.merge!(mot.canon => new_canon)
    end
    self.items_as_hash[mot.canon].add(mot)
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
  @items << mot
  @offsets << mot.offset
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

MIN_DISTANCE = 100
def distance_minimale
  @distance_minimale ||= MIN_DISTANCE # pour le moment TODO
end #/ distance_minimale

end #/Canon
