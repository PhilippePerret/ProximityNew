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

DATA_TABLE_TEXT_ITEMS = [
  {name:'Id',                 type:'INTEGER PRIMARY KEY AUTOINCREMENT', insert: false},
  {name:'Content',            type:'VARCHAR(30)'},
  {name:'Canon',              type:'VARCHAR(30)'},
  {name:'Type',               type:'VARCHAR(15)'},
  {name:'`Index`',            type:'INTEGER', property:'index'},
  {name:'Offset',             type:'INTEGER'},
  {name:'FileId',             type:'TINYINT', property:'file_id'},
  {name:'IndiceInFile',       type:'TINYINT', property:'indice_in_file'},
  {name:'MarkScrivenerStart', type:'VARCHAR(10)', property:'db_mark_scrivener_start'},
  {name:'MarkScrivenerEnd',   type:'VARCHAR(10)', property:'db_mark_scrivener_end'},
  {name:'Ignored',            type:'BOOLEAN', property:'is_ignored'}
]
DATA_TABLE_TEXT_ITEMS.each do |dcol|
  dcol[:property] ||= dcol[:name].downcase
  dcol.merge!(property_sym: dcol[:property].to_sym)
end

def insert_text_item(values)
  stm_insert_titem.execute(values)

  db.last_insert_row_id
end #/ insert_text_item

def load_text_item(id)
  stm_load_titem.execute(id)
  stm_load_titem.next
end #/ load_text_item
def stm_load_titem
  @stm_load_titem ||= db.prepare("SELECT * FROM text_items WHERE id = ?")
end #/ stm_load_titem

# Méthode publique pour actualiser l'offset et l'index d'un text-item
# @Params
#   @hdata    {Hash} {:id, :offset, :index}
def update_offset_index_titem(hdata)
  stm_update_offset_index.execute(hdata[:offset], hdata[:index], hdata[:indice_in_file], hdata[:id])
end #/ update_offset_index_titem

# Requête préparée pour actualiser l'offset et l'index d'un text-item du
# texte courant.
def stm_update_offset_index
  @stm_update_offset_index ||= db.prepare("UPDATE text_items SET Offset = ?, `Index` = ?, IndiceInFile = ? WHERE id = ?")
end #/ stm_update_offset_index

def update_text_item(hvalues)
  raise("udpate_text_item n'est pas encore implémenté.")
end #/ update_text_item

# Requête préparée pour l'enregistrement d'un nouveau text-item dans text_items
def stm_insert_titem
  @stm_insert_titem ||= begin
    colonnes = DATA_TABLE_TEXT_ITEMS.collect do |dcol|
      next if dcol[:insert] === false
      dcol[:name]
    end.compact
    interros = Array.new(colonnes.count, '?').join(VGE)
    colonnes = colonnes.join(VGE)
    db.prepare("INSERT INTO text_items (#{colonnes}) VALUES (#{interros})")
  end
end #/ stm_insert_titem

# Appelée *au début de chaque parsing*
def reset
  # On ne crée la table de configuration que si elle n'est pas encore créée
  create_base_if_necessary
  # Pour mettre tous les mots
  create_table_text_items('text_items', drop = true)
  # Pour mettre les formes lemmatisées
  create_table_lemmas
end #/ reset


# Pour ajouter un mot-canon à la table lemmas
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
  colonnes = DATA_TABLE_TEXT_ITEMS.collect do |dcol|
    "#{dcol[:name]} #{dcol[:type]}".freeze
  end.join(VGE).freeze
  db.execute("CREATE TABLE #{db_name}(#{colonnes})".freeze)
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
