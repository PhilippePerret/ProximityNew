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
# En bas de ce module, DB est instancié
def initialize(owner = nil)
  @owner = owner
end #/ initialize

# Appelée *au début de chaque parsing*
def reset
  # On ne crée la table de configuration que si elle n'est pas encore créée
  create_base_if_necessary
  # Pour mettre tous les mots
  create_table_text_items('text_items', drop = true)
  # Pour mettre les formes lemmatisées
  create_table_lemmas
end #/ reset

# Pour ajouter un mot et son canon dans la table `lemmas` qui permettra
# d'accélérer la recherche de canons.
def add_mots_et_canons(liste_doubles)
  # log("add_mot_et_canon(mot=#{mot.inspect}, canon=#{canon.inspect})")
  liste_doubles.each do |double|
    stm_set_lemma.execute(*double)
  end
  # stm_set_lemma.bind_params(*liste_doubles)
end #/ add_mot_et_canon

def add_mot_and_canon(mot, canon)
  stm_set_lemma.execute(mot,canon)
end #/ add_mot_and_canon

def stm_set_lemma
  @stm_set_lemma ||= db.prepare("INSERT INTO lemmas (mot, canon) VALUES (?, ?)".freeze)
end #/ stm_lemma

# @Return le canon du mot +mot+ s'il existe, Nil dans le cas contraire
def get_canon_of_mot(mot)
  res = stm_get_lemma.execute(mot)
  # log("Resultat de get_canon_of_mot(#{mot}) : #{res.inspect}")
  res = res.next
  return if res.nil?
  res[0]
end #/ get_canon_of_mot
def stm_get_lemma
  @stm_get_lemma ||= db.prepare("SELECT canon FROM lemmas WHERE mot = ? LIMIT 1".freeze)
end #/ stm_get_lemma

# Table pour créer la table des text-items
#
# La méthode permet de créer la table de tous les items, qui est créée lors du
# parsing du texte, ainsi que la table des text-items affichés (page courante)
def create_table_text_items(db_name = 'text_items'.freeze, dropping = false)
  db.execute("DROP TABLE IF EXISTS #{db_name}") if dropping
  # db.execute("CREATE TABLE #{db_name}(Id INTEGER PRIMARY KEY, Content VARCHAR(30), Canon VARCHAR(30), Type VARCHAR(15), Index INTEGER, FileId TINYINT, IndiceInFile TINYINT, Offset INTEGER, MarkScrivenerStart VARCHAR(10), MarkScrivenerEnd VARCHAR(10), Ignored BOOLEAN)".freeze)
  db.execute("CREATE TABLE #{db_name}(Id INTEGER PRIMARY KEY AUTOINCREMENT, Content VARCHAR(30), Canon VARCHAR(30), Type VARCHAR(15), `Index` INTEGER, FileId TINYINT, IndiceInFile TINYINT, Offset INTEGER, MarkScrivenerStart VARCHAR(10), MarkScrivenerEnd VARCHAR(10), Ignored BOOLEAN)".freeze)
end #/ create_table_text_items

def create_table_lemmas
  db.execute("DROP TABLE IF EXISTS lemmas".freeze)
  db.execute("CREATE TABLE IF NOT EXISTS lemmas (Mot VARCHAR(30), Canon VARCHAR(30))".freeze)
  db.execute("CREATE INDEX idxmot ON lemmas(mot)".freeze)
end #/ create_table_lemmas

def create_table_current_page
  create_table_text_items("current_page", drop = true)
end #/ create_table_current_page

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
  @path ||= owner.db_path
end #/ path

end #/TextSQLite
