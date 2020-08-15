# encoding: UTF-8
=begin
  Module pour gérer la base sqlite du texte
  On pourra l'utiliser par : Runner.itexte.db
=end
require 'sqlite3'

class TextSQLite
attr_reader :owner
# Pour obtenir un nouveau gestionnaire de base
# En bas de ce module, DB est instancié
def initialize(owner = nil)
  @owner = owner
end #/ initialize

# *** Raccourcis ***
def execute(req); db.execute(req) end
def results_as_hash=(val); db.results_as_hash = val end

# Pour pouvoir quitter proprement, il faut finaliser tous les statements
# préparé
def finalize_all_statements
  all_statements.each { |stm| stm.close }
end #/ finalize_all_statements
def all_statements
  @all_statements ||= []
end #/ all_statements


def begin_transaction
  db.execute("BEGIN TRANSACTION;".freeze)
end #/ begin_transaction
def end_transaction
  db.execute("END TRANSACTION;".freeze)
end #/ end_transaction

# Pour insérer une liste de text-items
# +liste+ est une liste Array d'instances TextItem (Mot ou NonMot)
# Ça peut être aussi une liste des listes de valeurs.
def insert_text_items(liste)

  if not liste.first.is_a?(Array)
    last_length = nil
    last_offset = nil
    liste = liste.collect do |i|
      if i.offset.nil?
        if last_offset.nil?
          # Cela se produit quand c'est le premier élément qui n'a pas d'offset
          # Dans ce cas, on prend l'offset du mot qui possède actuellement
          # l'index du nouveau mot dans la table
          db_res = get_titem_by_index(i.index + Runner.iextrait.from_item, as_hash = true)
          log("[insert_text_items] Premier item sans offset défini.#{RC}titem: #{i.inspect}#{RC}db_res: #{db_res.inspect}")
          last_offset = db_res['Offset']
          last_length = 0
        end
        # log("Le mot #{i.content.inspect} d'index #{i.index} n'a pas d'offset.")
        i.offset = last_offset + last_length
        # log("Je lui ai mis #{i.offset} calculé d'après le mot précédent.")
      end
      last_offset = i.offset
      last_length = i.length
      # On renvoie les valeurs
      i.db_values
    end
  end
  # log("Liste pour l'insertion multiple : #{liste.inspect}")
  # log("Pour rappel, les colonnes : #{titems_colonnes_and_interrogations.first.inspect}")
  # stm_insert_titem.execute(*liste)
  log("*** Insertion de #{liste.count} text-items…")
  start_time = Time.now.to_f
  liste.each do |args|
    # log("    Insertion de : #{args.inspect}")
    stm_insert_titem.execute(*args)
  end
  stop_time = Time.now.to_f
  log("=== Insertion opérée en #{stop_time - start_time} secs.")
end #/ insert_text_items
def insert_text_item(values)
  stm_insert_titem.execute(values)
  return db.last_insert_row_id
end #/ insert_text_item
# Requête préparée pour l'enregistrement d'un nouveau text-item dans text_items
def stm_insert_titem
  @stm_insert_titem ||= begin
    colonnes, interros = titems_colonnes_and_interrogations
    stm = db.prepare("INSERT INTO text_items (#{colonnes}) VALUES (#{interros})".freeze)
    all_statements << stm
    stm
  end
end #/ stm_insert_titem

def delete_text_items(params)
  case params
  when Array
    if params.count == 1
      # log("Destruction du text-item d'index #{params.first.inspect}.")
      stm_delete_text_item.execute(params.first)
    else
      stm_delete_text_items_by_list(params).execute(params)
    end
  when Hash
    stm_delete_text_items_by_range.execute(params[:from], params[:from] + params[:for] - 1)
  else
    raise "Les paramètres pour TextSQLite#delete_text_items doit être soit un liste contenant les index des text-items, soit une table définissant :from et le nombre d'items :for."
  end
end #/ delete_text_items
def stm_delete_text_items_by_list(liste)
  interros = Array.new(liste.count,'?').join(VGE)
  request = "DELETE FROM text_items WHERE Idx IN (#{interros})".freeze
  # log("Requête de destruction : #{request}")
  stm = db.prepare(request)
  all_statements << stm
  stm
end #/ stm_delete_text_items_by_list
def stm_delete_text_items_by_range
  @stm_delete_text_items_by_range ||= begin
    request = "DELETE FROM text_items WHERE Idx >= ? AND Idx <= ?".freeze
    # log("Requête de destruction : #{request}")
    stm = db.prepare(request)
    all_statements << stm
    stm
  end
end #/ stm_delete_text_items_by_range
def stm_delete_text_item
  @stm_delete_text_item ||= begin
    stm = db.prepare("DELETE FROM text_items WHERE Idx = ?".freeze)
    all_statements << stm
    stm
  end
end #/ stm_delete_text_item

def get_titem_by_index(index, as_hash = nil)
  db.results_as_hash = as_hash unless as_hash.nil?
  # log("-> get_titem_by_index(index:#{index.inspect}, as_hash:#{as_hash.inspect})")
  res = stm_titem_by_index.execute(index)

  res.next
end #/ get_titem_by_index
def stm_titem_by_index
  @stm_titem_by_index ||= begin
    colonnes, interros = titems_colonnes_and_interrogations
    cmd = "SELECT Id, #{colonnes} FROM text_items WHERE Idx = ? LIMIT 1".freeze
    # log("Requête préparée pour récupérer un titem par son index : #{cmd.inspect}")
    stm = db.prepare(cmd)
    all_statements << stm
    stm
  end
end #/ stm_titem_by_index

# Renvoie les données du canon du mot +mot+, c'est-à-dire une table
# contenant ['Mot', 'Type', 'Canon', 'Canon_alt']
#
def get_canon(mot)
  db.results_as_hash = true
  res = stm_get_canon.execute(mot.downcase)
  res = res.next
  db.results_as_hash = false

  res
end #/ get_canon
def stm_get_canon
  @stm_get_canon ||= begin
    stm = db.prepare("SELECT * FROM lemmas WHERE mot = ? LIMIT 1")
    all_statements << stm
    stm
  end
end #/ stm_get_canon

# Pour ajouter un mot-canon à la table lemmas
def add_mot_and_canon(mot, type, canon)
  canon, canon_alt = canon.split(BARREV)
  stm_set_lemma.execute(mot, type, canon)
end #/ add_mot_and_canon
def stm_set_lemma
  @stm_set_lemma ||= db.prepare("INSERT INTO lemmas (mot, type, canon, canon_alt) VALUES (?, ?, ?, ?)".freeze)
end #/ stm_lemma

# Au cours du parsing, on a besoin de savoir si le mot +mot+ possède déjà
# la définition de son canon dans la base de données (de l'application).
# Cette méthode retourne true si c'est le cas, false dans le cas contraire
def canon_exists_for?(mot)
  res = stm_for_canon_existence.execute(mot)
  res.next != nil
end #/ canon_exists_for?
def stm_for_canon_existence
  @stm_for_canon ||= begin
    stm = db.prepare("SELECT canon FROM lemmas WHERE mot = ? LIMIT 1")
    all_statements << stm
    stm
  end
end #/ stm_for_canon_existence


def load_text_item(id)
  stm_load_titem.execute(id)
  stm_load_titem.next
end #/ load_text_item
def stm_load_titem
  @stm_load_titem ||= begin
    stm = db.prepare("SELECT * FROM text_items WHERE id = ? LIMIT 1")
    all_statements << stm
    stm
  end
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
  @stm_update_offset_index ||= begin
    stm = db.prepare("UPDATE text_items SET Offset = ?, Idx = ?, IndiceInFile = ? WHERE id = ?")
    all_statements << stm
    stm
  end
end #/ stm_update_offset_index

def update_text_item(hvalues)
  titem_id = hvalues.delete(:id)
  values = []
  modifications = hvalues.collect do |k, v|
    values << case v
              when TrueClass  then 'TRUE'
              when FalseClass then 'FALSE'
              when NilClass   then 'NULL'
              else v
              end
    # On retourne la modification
    "#{k} = ?"
  end
  values << titem_id
  request = "UPDATE text_items SET #{modifications.join(VGE)} WHERE id = ?".freeze
  stm = db.prepare(request)
  stm.execute(*values)
end #/ update_text_item

def update_prop_ignored(titem, value)
  stm_update_ignored.execute(value ? 'TRUE' : 'FALSE', titem.id)
end #/ update_prop_ignored
def stm_update_ignored
  @stm_update_ignored ||= begin
    stm = db.prepare("UPDATE text_items SET Ignored = ? WHERE id = ?")
    all_statements << stm
    stm
  end
end #/ stm_update_ignored


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
  # TABLE Pour mettre tous les mots (si nécessaire)
  create_table_text_items('text_items', drop = true)
  # TABLE pour enregistrer les opérations (si nécessaire)
  create_table_operations

  # *** TRIGGERS à supprimer quand on parse ***

  # TRIGGER Pour updater automatiquement les index et offsets quand on insert
  # un nouveau mot dans la table text_items
  drop_trigger_on_insert_titem
  # TRIGGER Pour conserver les opérations
  drop_triggers_operations

  # TRIGGER pour updater automatiquement les index et les offsets quand on
  # supprime un text-item dans la table text_items
  create_trigger_on_delete_titem

  # TRIGGER pour enregistrer les opérations faites
  # sur le texte.
  create_trigger_operations
end #/ reset



def execute(*args)
  begin
    db.execute(*args)
  rescue SQLite3::Exception => e
    erreur(e)
  end
end #/ execute
def db
  @db ||= SQLite3::Database.open(path)
end #/ db
def close
  db.close unless @db.nil?
  @db = nil
end #/ close
def path
  @path ||= owner.db_path
end #/ path

end #/TextSQLite
