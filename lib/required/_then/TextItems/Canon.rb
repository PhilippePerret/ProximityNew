# encoding: UTF-8
class Canon
class << self
  def init
    @items_as_hash = {}
    @items = []
  end #/ init
  def add(mot)
    unless @items_as_hash.key?(mot.canon)
      new_canon = new(mot.canon)
      @items << new_canon
      @items_as_hash.merge!(mot.canon => new_canon)
    end
    @items_as_hash[mot.canon].add(mot)
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
  @items << mot
end #/ add
end #/Canon
