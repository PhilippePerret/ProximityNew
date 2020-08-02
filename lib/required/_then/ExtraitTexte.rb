# encoding: UTF-8
class ExtraitTexte
DEFAULT_NOMBRE_ITEMS = 150
class << self

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :itexte, :from_item, :to_item
def initialize itexte, params
  @itexte     = itexte
  @from_item  = params[:from]
  @to_item    = params[:to] || @from_item + DEFAULT_NOMBRE_ITEMS
end #/ initialize
def output
  ary_items = []
  (from_item..to_item).each do |idx|
    itexte.items[idx] || break
    ary_items << itexte.items[idx].content
  end
  ary_items.join(SPACE)
end #/ output
end #/ExtraitTexte
