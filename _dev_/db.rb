# encoding: UTF-8
# Chemin d'accès à la table à voir
DB_PATH = "/Users/philippeperret/Programmation/ProximityNew/asset/exemples/simple_text_prox/db.sqlite"

REQUESTS = []

# request = <<-SQL.freeze
# CREATE TRIGGER tryupdate AFTER INSERT on text_items
# BEGIN
#   INSERT INTO text_items (Content) VALUES ("Bonjour");
# END;
# SQL
# # REQUESTS << request

# TEXT-ITEMS
request = "SELECT Idx, Content, Offset FROM text_items WHERE Idx < 15;"
REQUESTS << [request, :afficher_mots]

# TABLES
# --------------
# REQUESTS << "SELECT name FROM sqlite_master WHERE type = 'table';"

# TRIGGERS
# ---------
# REQUESTS << "SELECT name FROM sqlite_master WHERE type = 'trigger';"


require 'sqlite3'

db = SQLite3::Database.open(DB_PATH)


def afficher_mots(db_res)
  db_res.each do |row|
    index, content, offset = row
    puts "#{index.to_s.ljust(8)}#{content.ljust(20)}#{offset.to_s.ljust(6)}"
  end
end #/ afficher_mots
begin
  method = nil
  REQUESTS.each do |request|
    puts "Requête : #{request.inspect}"
    if request.is_a?(Array)
      request, method = request
    else
      method = nil
    end
    res = db.execute(request)
    if method
      send(method.to_sym, res)
    else
      puts res.inspect
    end
  end
rescue SQLite3::Exception => e
  puts "ERREUR SQL: #{e.message}"
end
