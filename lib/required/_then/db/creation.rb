# encoding: UTF-8
=begin
  Tout ce qui concerne la création de la base SQLite du texte à travailler
=end
class TextSQLite
# Données de la table principale Text_Items qui consigne tous les mots
# du texte.
DATA_TABLE_TEXT_ITEMS = [
  {name:'Id',                 type:'INTEGER PRIMARY KEY AUTOINCREMENT', insert: false},
  {name:'Content',            type:'VARCHAR(30)'},
  {name:'IsMot',              type:'BOOLEAN',     property:'is_mot'},
  {name:'Canon',              type:'VARCHAR(30)'},
  {name:'Type',               type:'VARCHAR(15)'},
  {name:'Idx',                type:'INTEGER',     property:'index'},
  {name:'Offset',             type:'INTEGER'},
  {name:'FileId',             type:'TINYINT',     property:'file_id'},
  {name:'IndiceInFile',       type:'TINYINT',     property:'indice_in_file'},
  {name:'MarkScrivenerStart', type:'VARCHAR(10)', property:'db_mark_scrivener_start'},
  {name:'MarkScrivenerEnd',   type:'VARCHAR(10)', property:'db_mark_scrivener_end'},
  {name:'Ignored',            type:'BOOLEAN',     property:'is_ignored'}
]
DATA_TABLE_TEXT_ITEMS.each do |dcol|
  dcol[:property] ||= dcol[:name].downcase
  dcol.merge!(property_sym: dcol[:property].to_sym)
end

# Code pour la création du trigger qui doit gérer l'insertion de
# nouveau mot.
# Quand un nouveau mot est inséré à un offset, tous les mots suivants doivent
# augmenter leur index et leur offset.
CODE_TRIGGER_ON_INSERT_TITEM = <<-SQL.freeze.strip
CREATE TRIGGER update_index_and_offset_on_insert_titem BEFORE INSERT
  ON text_items
  BEGIN
    UPDATE text_items
    SET `Idx` = (`Idx` + 1), `Offset` = (`Offset` + LENGTH(New.Content))
    WHERE Idx >= New.Idx;
  END;
SQL

CODE_TRIGGER_ON_DELETE = <<-SQL.freeze.strip
CREATE TRIGGER update_index_n_offset_on_delete_titem
    AFTER DELETE
    ON text_items
    BEGIN
        UPDATE text_items
        SET `Idx` = `Idx` - 1, `Offset` = `Offset` - LENGTH(Old.Content)
        WHERE Idx > Old.Idx ;
    END;
SQL

class << self

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

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
  db.execute("CREATE TABLE IF NOT EXISTS lemmas (Mot VARCHAR(30), Type VARCHAR(15), Canon VARCHAR(25), Canon_alt VARCHAR(25))".freeze)
  db.execute("CREATE INDEX idxmot ON lemmas(Mot)".freeze)
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

def create_trigger_on_delete_titem
  db.execute("DROP TRIGGER IF EXISTS update_index_n_offset_on_delete_titem;")
  db.execute(CODE_TRIGGER_ON_DELETE)
end #/ create_trigger_on_delete_titem

# Trigger quand on insert une donnée dans text_items
# Noter que ce trigger est détruit quand on parse le code, pour ne pas
# causer un appel à chaque insertion.
def create_trigger_on_insert_titem
  db.execute(CODE_TRIGGER_ON_INSERT_TITEM)
end #/ create_trigger_on_insert_titem

def drop_trigger_on_insert_titem
  db.execute("DROP TRIGGER IF EXISTS update_index_and_offset_on_insert_titem;")
end #/ drop_trigger_on_insert_titem
end #/TextSQLite
