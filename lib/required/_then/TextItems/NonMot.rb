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
def is_mot ; false end
def ignored?
  is_ignored === true
end #/ ignored?
end #/NonMot < TexteItem
