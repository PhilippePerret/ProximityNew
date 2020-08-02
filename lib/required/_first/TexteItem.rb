# encoding: UTF-8
class TexteItem
class << self
  attr_reader :items

  def init
    @items = []
  end #/ init

  def create(params, offset)
    item = new(params[0..1])
    item.canon = params[2] if item.is_a?(Mot)
    item.offset = offset
    send(:on_create, item) if respond_to?(:on_create)
    return item
  end #/ create

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

attr_reader :content, :type, :canon
# Index dans la liste des items principaux (items du parent)
attr_accessor :index, :offset
def initialize(params)
  # Note : sera redéfini par chaque sous-classe
  @content, @type = params
end #/ initialize

# Retourne le décalage de l'item (paragraphe, phrase, mot, non-mot) par
# rapport au début du texte. Cet offset doit toujours être calculé
def offset
  @offset ||= begin
    parent.offset + pre_items_length
  end
end #/ offset

def length
  @length ||= content.length + 1
end #/ length

end #/TexteItem
