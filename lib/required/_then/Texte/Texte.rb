# encoding: UTF-8
require 'fileutils'

class Texte
include ConfigModule
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :path, :lemmatized_file_path
attr_reader :items
# Le premier mot (ou non mot) courant
attr_accessor :current_first_item

def initialize(path)
  @path = path
  # db.create_base_if_necessary
  # db.execute("UPDATE configuration SET value = #{Time.now.to_i} WHERE name = 'LastOpening'")
  # db.db.close if db.db
rescue Exception => e
  erreur(e)
end #/ initialize

def reset(key)
  instance_variable_set("@#{key}", nil)
end #/ reset

# def db
#   @db ||= TextSQLite.new(self)
# end #/ db

# Reconstruction totale du texte.
def rebuild
  File.delete(rebuild_file_path) if File.exists?(rebuild_file_path)
  File.open(rebuild_file_path,'wb') do |f|
    items.each { |titem| f.write(titem.content) }
  end
  CWindow.log("Texte reconstitué avec succès.".freeze)
end #/ rebuild

# Essai de recomptage de tout pour voir le temps que ça prend
def recompte(params = nil)
  params ||= {}
  start_time = Time.now.to_f
  offset = 0
  nb = 0
  # Les canons qu'il faudra actualiser
  canons_to_update = {}
  params.merge!(from: 0) unless params.key?(:from)
  idx = params[:from] - 1
  while titem = self.items[idx += 1]
    # Si le décalage du mot change et que son canon n'est pas encore à
    # actualiser, il faut l'enregistrer pour l'actualiser
    if titem.mot? && titem.offset != offset && !canons_to_update.key?(titem.canon)
      raise "Le canon de #{titem.inspect} n'est pas défini (il devrait l'être)" if titem.canon.nil? || titem.icanon.nil?
      canons_to_update.merge!(titem.canon => titem.icanon)
    end
    titem.offset = offset
    titem.index  = idx
    offset += titem.length + 1 # approximatif car on n'ajoute pas toujours 1 espace
    nb += 1
  end

  # Actualisation des canons
  # ------------------------
  erreurs = []
  canons_to_update.each do |canon, icanon|
    if icanon.nil?
      erreurs << "ERREUR CANON: Le canon #{canon.inspect} est nul"
    else
      icanon.update
    end
  end
  unless erreurs.empty?
    CWindow.error("Une erreur est survenue avec les canons. Quitter et consulter le journal.")
    log("### ERREUR UPDATE CANON ####{RC}#{erreurs.join(RC)}")
  end

  end_time = Time.now.to_f
  CWindow.log("Fin du recalcul. Quitter et pour voir le temps.")

  log("Durée du recomptage de #{nb} items : #{end_time - start_time}")
end #/ recompte

# On doit forcer la ré-analyse du texte
def reproximitize
  CWindow.logWind.write('Ré-analyse du texte…')
  parse # maintenant, reprend tout
  CWindow.logWind.write('Texte analysé avec succès.')
  return true
end #/ reproximitize

def save
  data = {
    items: items,
    canons:  Canon.items_as_hash,
    path:  path,
    updated_at: Time.now,
    created_at: Time.now
  }
  File.open(data_path,'wb'){|f| Marshal.dump(data,f)}
end #/ save

def load
  @data = Marshal.load(File.read(data_path))
  @items = @data[:items]
  @current_first_item = config[:last_first_index]
  Canon.items_as_hash = @data[:canons]
end #/ load


# Retourne TRUE s'il faut procéder à l'analyse à nouveau
def out_of_date?
  return true unless File.exists?(data_path)
  return File.stat(data_path).mtime < File.stat(path).mtime
end #/ out_of_date?



def distance_minimale_commune
  @distance_minimale_commune ||= config[:distance_minimale_commune] || DISTANCE_MINIMALE_COMMUNE
end #/ distance_minimale_commune

# ---------------------------------------------------------------------
#
#  Question methods
#
# ---------------------------------------------------------------------
def projet_scrivener?
  extension == '.scriv' || extension == '.scrivx'
end #/ projet_scrivener?

# ---------------------------------------------------------------------
#
#   CHEMINS
#
# ---------------------------------------------------------------------

# Chemin d'accès au fichier principal contenant tout le texte.
# C'est lui qui servira à relever tous les mots et qui sera
# modifié à la fin pour refléter des changements.
def main_file_txt
  @main_file_txt ||= File.join(prox_folder,'full_text.txt')
end #/ main_file_txt

def rebuild_file_path
  @rebuild_file_path ||= File.join(prox_folder, ('full_text_final-%s.txt'.freeze % Time.now.strftime('%d-%m-%Y')))
end #/ rebuild_file_path

# Chemin d'accès au fichier qui contient seulement les mots du texte,
# dans l'ordre, pour lemmatisation
def only_mots_path
  @only_mots_path ||= File.join(prox_folder, 'only_mots.txt')
end #/ only_mots_path

def config_path
  @config_path ||= File.join(prox_folder,'config.json')
end #/ config_path
def config_default_data
  {
    last_first_index: 0,
    distance_minimale_commune: 1000,
    last_opening: Time.now.to_i
  }
end #/ config_default_data

def db_path
  @db_path ||= File.join(prox_folder, 'db.sqlite')
end #/ db_path

def data_path
  @data_path ||= File.join(prox_folder,"#{affixe}-prox.data.msh")
end #/ data_path

def corrected_text_path
  @corrected_text_path ||= File.join(prox_folder,"#{affixe}_c#{extension}".freeze)
end #/ corrected_text_path

def prox_folder
  @prox_folder ||= begin
    File.join(folder,"#{affixe}_prox").tap { |pth| `mkdir -p "#{pth}"` }
  end
end #/ prox_folder

def folder
  @folder ||= File.dirname(path)
end #/ folder
def affixe
  @affixe ||= File.basename(path, extension)
end #/ affixe
def extension
  @extension ||= File.extname(path)
end #/ extension


end #/Texte
