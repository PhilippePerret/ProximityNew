# encoding: UTF-8
=begin
  Module pour gérer la base sqlite du texte
  On pourra l'utiliser par : Runner.itexte.db
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
def create_base_if_necessary
  begin
    db.execute("CREATE TABLE IF NOT EXISTS configuration (name TEXT, type TEXT, value TEXT)")
    db.execute("INSERT INTO configuration (name, type) VALUES ('Path', 'string')")
    db.execute("INSERT INTO configuration (name, type) VALUES ('LastIndexMot', 'number')")
    db.execute("INSERT INTO configuration (name, type) VALUES ('LastOpening', 'number')")
  rescue SQLite3::Exception => e
    error(e)
  ensure
    # db.close if db
  end
end #/ create_base_if_necessary

def execute(code)
  begin
    db.execute(code)
  rescue SQLite3::Exception => e
    erreur(e)
  ensure
    # db.close
  end
end #/ execute
def db
  @db ||= SQLite3::Database.open(path)
end #/ db
def path
  @path ||= File.join(owner.prox_folder,'db.sqlite')
end #/ path

end #/TextSQLite
