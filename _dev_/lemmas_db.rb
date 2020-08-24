# encoding: UTF-8
# Chemin d'accès à la base de l'application Proximity
DB_PATH = "/Users/philippeperret/Programmation/ProximityNew/lib/data.db"

REQUESTS = []

# TEXT-ITEMS
request = "SELECT Mot, Canon, Type FROM lemmas LIMIT 20".freeze
REQUESTS << [request, :afficher_mots]


require 'sqlite3'

db = SQLite3::Database.open(DB_PATH)


def afficher_mots(db_res)
  puts "db_res: #{db_res.inspect}"
  db_res.each do |row|
    mot, canon, type = row
    puts "#{mot.to_s.ljust(20)}#{canon.ljust(20)}#{type.to_s.ljust(10)}"
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
