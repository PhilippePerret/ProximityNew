# encoding: UTF-8
require 'fileutils'

class Texte
include ConfigModule
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :path
attr_reader :items
# Le premier mot (ou non mot) courant
attr_accessor :current_first_item

def initialize(path)
  @path = path
rescue Exception => e
  erreur(e)
end #/ initialize

def reset(key)
  instance_variable_set("@#{key}", nil)
end #/ reset

def save
  data = {
    path:  path,
    updated_at: Time.now,
    created_at: Time.now
  }
  File.open(data_path,'wb'){|f| Marshal.dump(data,f)}
  # raise "Il faut revoir la procédure de sauvarde du texte."
end #/ save

# Méthode de débuggage pour voir les items du texte
def debug_items(quand = nil)
  debug_titems(items, titre: "#{RC*2}Text-items du texte #{quand} :")
end #/ debug_items

# Instance base de donnée propre au texte/projet
def db
  @db ||= TextSQLite.new(self)
end #/ db

def load
  @data = Marshal.load(File.read(data_path)) # encore utile ?…
  @current_first_item = config[:last_first_index]
  return true
rescue Exception => e
  erreur(e)
  return false
end #/ load

# L'instance operator (qui sert pour le moment à enregistrer toutes les
# opérations de modification du texte).
def operator
  @operator ||= TextOperator.new(self)
end #/ operator

# L'instance annulateur
def cancellor
  @cancellor ||= Cancellor.new(self)
end #/ cancellor

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
  extension == '.scriv'
end #/ projet_scrivener?

def projet_scrivener
  @projet_scrivener ||= begin
    Scrivener::Projet.new(path,self) if projet_scrivener?
  end
end #/ projet_scrivener
# ---------------------------------------------------------------------
#
#   CHEMINS
#
# ---------------------------------------------------------------------

# Chemin d'accès au fichier pour enregistrer toutes les opérations
# exécutées sur le texte
def operations_file_path
  @operations_file_path ||= File.join(prox_folder,'operations.txt').freeze
end #/ operations_file_path

# Chemin d'accès au fichier principal contenant tout le texte (sauf
# pour projet scrivener)
# C'est lui qui servira à relever tous les mots et qui sera
# modifié à la fin pour refléter des changements.
def full_text_path
  @full_text_path ||= File.join(prox_folder,'full_text.txt').freeze
end #/ full_text_path

def lemma_data_path
  @lemma_data_path ||= "#{only_mots_path}_lemma.data".freeze
end #/ lemma_data_path

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
    last_first_index:           0,
    distance_minimale_commune:  1000,
    last_opening:               Time.now.to_i,
    apostrophes_courbes:        false,
  }
end #/ config_default_data

def db_path
  @db_path ||= File.join(prox_folder, 'db.sqlite')
end #/ db_path

def data_path
  @data_path ||= File.join(prox_folder,"data.msh")
end #/ data_path

def corrected_text_path
  @corrected_text_path ||= File.join(prox_folder,"corrected#{extension}".freeze)
end #/ corrected_text_path

def prox_folder
  @prox_folder ||= begin
    File.join(folder,"#{affixe}_prox").tap { |pth| `mkdir -p "#{pth}"` }
  end
end #/ prox_folder

def folder
  @folder ||= File.dirname(path)
end #/ folder
def fname
  @fname ||= File.basename(path)
end #/ fname
def affixe
  @affixe ||= File.basename(path, extension)
end #/ affixe
def extension
  @extension ||= File.extname(path)
end #/ extension


end #/Texte
