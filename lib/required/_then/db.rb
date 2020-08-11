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
  {name:'IsMot',              type:'BOOLEAN', property:'is_mot'},
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

# *** Raccourcis ***
def execute(req); db.execute(req) end
def results_as_hash=(val); db.results_as_hash = val end

def insert_text_item(values)
  values = values.collect do |v|
    case v
    when true then 'TRUE'
    when false then 'FALSE'
    else v
    end
  end
  stm_insert_titem.execute(values)

  db.last_insert_row_id
end #/ insert_text_item

def get_titem_by_index(index, as_hash = false)
  db.results_as_hash = as_hash
  res = stm_titem_by_index.execute(index)
  res.next
end #/ get_titem_by_index
def stm_titem_by_index
  @stm_titem_by_index ||= begin
    colonnes, interros = titems_colonnes_and_interrogations
    db.prepare("SELECT #{colonnes} FROM text_items WHERE `Index` = ?")
  end
end #/ stm_titem_by_index

def get_canon(mot)
  db.results_as_hash = true
  res = stm_get_canon.execute(mot.downcase)
  db.results_as_hash = false

  res.next
end #/ get_canon
def stm_get_canon
  @stm_get_canon ||= db.prepare("SELECT * FROM lemmas WHERE mot = ? LIMIT 1")
end #/ stm_get_canon


def load_text_item(id)
  stm_load_titem.execute(id)
  stm_load_titem.next
end #/ load_text_item
def stm_load_titem
  @stm_load_titem ||= db.prepare("SELECT * FROM text_items WHERE id = ? LIMIT 1")
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

def update_prop_ignored(titem, value)
  stm_update_ignored.execute(value ? 'TRUE' : 'FALSE', titem.id)
end #/ update_prop_ignored
def stm_update_ignored
  @stm_update_ignored ||= db.prepare("UPDATE text_items SET Ignored = ? WHERE id = ?")
end #/ stm_update_ignored

# Requête préparée pour l'enregistrement d'un nouveau text-item dans text_items
def stm_insert_titem
  @stm_insert_titem ||= begin
    colonnes, interros = titems_colonnes_and_interrogations
    db.prepare("INSERT INTO text_items (#{colonnes}) VALUES (#{interros})")
  end
end #/ stm_insert_titem

def titems_colonnes_and_interrogations
  @titems_colonnes_and_interrogations ||= begin
    colonnes = DATA_TABLE_TEXT_ITEMS.collect do |dcol|
      next if dcol[:insert] === false
      dcol[:name]
    end.compact
    interros = Array.new(colonnes.count, '?').join(VGE)
    colonnes = colonnes.join(VGE)
    [colonnes, interros]
  end
end #/ titems_colonnes_and_interrogations

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
def add_mot_and_canon(mot, type, canon)
  stm_set_lemma.execute(mot, type, canon)
end #/ add_mot_and_canon
def stm_set_lemma
  @stm_set_lemma ||= db.prepare("INSERT INTO lemmas (mot, type, canon) VALUES (?, ?, ?)".freeze)
end #/ stm_lemma

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
  db.execute("CREATE TABLE IF NOT EXISTS lemmas (Mot VARCHAR(30), Type VARCHAR(15), Canon VARCHAR(30))".freeze)
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
