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

# Mis à true quand une modification a été opérée
attr_accessor :modified

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
    items: items,
    path:  path,
    updated_at: Time.now,
    created_at: Time.now
  }
  File.open(data_path,'wb'){|f| Marshal.dump(data,f)}
  # raise "Il faut revoir la procédure de sauvarde du texte."
  self.modified = false
end #/ save

# Actualise le texte
# ------------------
# Cette méthode est appelée lorsqu'on quitte une page (pour passer à la suivante
# ou pour quitter l'application) et que la page courante a été modifiée. Il faut
# à présent reporter les modifications sur le texte lui-même.
# Ces modifications portent essentiellement sur les items ajoutés/supprimés/
# modifiés. En fait, il faut :
#   [1] Remplacer les items actuels (itexte.items) correspondant à l'extrait
#       (donc de iextrait.from_item à iextrait.to_item) par les nouveaux items
#   [2] Procéder au recomptage des index et offsets de tous les mots.
#   [3] Indiquer que le texte a été modifié pour pouvoir le sauvegarder
#
def update
  # log("-> Texte#update")
  extr = Runner.iextrait
  # [1]
  titems_avant = extr.from_item > 0 ? items[0...(extr.from_item)] : []
  titems_apres = items[(extr.to_item+1)..-1]
  @items = titems_avant + extr.extrait_titems + titems_avant

  # Débug
  # debug_items("après insertion extrait (avant recomptage)")

  # [2]
  recompte
  # debug_items("après recomptage")
  # [3]
  self.modified = true
end #/ update

# Méthode de débuggage pour voir les items du texte
def debug_items(quand = nil)
  debug_titems(items, titre: "#{RC*2}Text-items du texte #{quand} :")
end #/ debug_items

# Méthode qui recompte tout, les offsets, les index, etc.
def recompte(params = nil)
  start_time = Time.now.to_f
  params  ||= {}
  offset  = 0
  nb      = 0 # pour connaitre le nombre de text-items traités
  # Premier index
  # -------------
  # En fait, ça va tellement vite, même avec un texte long, qu'on repart
  # toujours du départ, même si params[:from] est défini.
  # idx = params[:from] - 1
  idx = -1 # pour que le premier soit 0

  # Si c'est un projet scrivener, on va aussi redéfinir l'index
  # de chaque mot dans chaque fichier. Cela permettra d'enregistrer les
  # opération de façon très précise et juste. Par exemple, la phrase
  # "'Bonjour' Mot inséré avant le 23e mot ('toi') dans le fichier 4"
  # Bien noter que c'est seulement utile pour un projet Scrivener (donc
  # avec plusieurs fichiers).
  # Noter que le premier mot aura l'indice 1.
  idx_mot_in_file = 0
  current_file_id = nil # pour savoir quand on change de fichier

  while titem = self.items[idx += 1] # tant qu'il y a un item

    titem.reset # pour forcer les recalculs

    # Pour savoir si l'item a changé. Il a changé si son index ou son
    # offset ont changé.
    has_changed = titem.offset != offset || titem.index != idx
    titem.offset = offset
    titem.index  = idx
    # Pour gérer l'index dans le fichier (projet Scrivener)
    if current_file_id != titem.file_id
      current_file_id = titem.file_id.dup
      idx_mot_in_file = 0
    end
    if titem.mot?
      indice_in_file = (idx_mot_in_file += 1)
      has_changed = has_changed || titem.indice_in_file != indice_in_file
      titem.indice_in_file = indice_in_file
    end

    # Si l'offset, l'index ou l'indice du mot dans le fichier a changé,
    # on actualise le mot dans la base de données
    if has_changed
      titem.update_offset_and_index
      log("Le mot #{titem.cio} a été actualisé".freeze)
    end

    # Le nouvel offset. Maintenant, il est très juste puisque l'intégralité
    # du texte, non-mot compris, est enregistré dans Texte@items.
    offset += titem.length
    nb += 1
  end

  end_time = Time.now.to_f
  CWindow.log("Fin du recalcul (la durée se trouve dans debug.log).")

  debug("Durée du recomptage de #{nb} items : #{end_time - start_time}")
end #/ recompte

def error_canon_inexistant
  err_msg = "[Erreur Recomptage] Le canon de #{titem.inspect} n'est pas défini (il devrait l'être)"
  environ = ''
  ((idx - 10)..(idx + 10)).each do |idx2|
    next if idx2 < 0
    break if Runner.itexte.items[idx2].nil?
    environ << Runner.itexte.items[idx2].content
  end
  err_msg << " (environnement : #{environ})"
  unless titem.file_id.nil?
    err_msg << ". Le mot se trouve dans le fichier #{titem.file_id} (#{ScrivFile.get_path_by_file_id(titem.file_id)})"
  end
  err_msg = err_msg.freeze
  add_parsing_error(ParsingError.new(err_msg))
  log(err_msg)
end #/ error_canon_inexistant

# On doit forcer la ré-analyse du texte
def reproximitize
  CWindow.logWind.write('Ré-analyse du texte…')
  parse # maintenant, reprend tout
  CWindow.logWind.write('Texte analysé avec succès.')
  return true
end #/ reproximitize

# Instance base de donnée propre au texte/projet
def db
  @db ||= TextSQLite.new(self)
end #/ db

def load
  @data = Marshal.load(File.read(data_path))
  @items = @data[:items]
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

# Retourne true si le texte est enregistré (si ses modifications ont été
# enregistrés)
def saved?
  !(self.modified === true)
end #/ saved?

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
