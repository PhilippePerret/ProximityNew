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
attr_reader :canon
def initialize(canon)
  @canon = canon
  @items = []
end #/ initialize

# Ajout d'un mot au canon
def add(mot)
  mot.icanon = self
  @items << mot
end #/ add

def count
  @items.count
end #/ count


MIN_DISTANCE = 100
def distance_minimale
  @distance_minimale ||= MIN_DISTANCE # pour le moment TODO
end #/ distance_minimale

end #/Canon
