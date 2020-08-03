# encoding: UTF-8
=begin
  Module pour gérer la base sqlite du texte
=end
require 'sqlite3'
class TextSQLite
class << self

end # /<< self
attr_reader :owner
# Pour obtenir un nouveau gestionnaire de base
def initialize(owner)
  @owner = owner
end #/ initialize
# Pour créer le fichier base pour le texte
def create_db

end #/ create_db
def db
  @db ||= SQLite3::Database.open(path)
end #/ db
def path
  @path ||= File.join(owner.folder_prox,'db.sqlite')
end #/ path
end #/TextSQLite
