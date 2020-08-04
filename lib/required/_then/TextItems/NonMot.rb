# encoding: UTF-8
class NonMot < TexteItem
class << self
end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
def non_mot? ; true end
def mot? ; false end
def ponctuation?; true end
end #/NonMot < TexteItem
