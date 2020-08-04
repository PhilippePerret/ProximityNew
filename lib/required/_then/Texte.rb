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
  CWindow.log("Je dois reconstruire le texte.")
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
      raise "Le canon de #{titem.inspect} n'est pas défini" if titem.canon.nil? || titem.icanon.nil?
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
  File.delete(data_path) if File.exists?(data_path)
  parse || return
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

# Il faut voir s'il est nécessaire de parser le fichier. C'est nécessaire
# si le fichier d'analyse n'existe pas ou s'il est plus vieux que le
# nouveau texte.
def parse_if_necessary
  if out_of_date?
    # log "Le fichier doit être actualisé"
    parse || return
    log("👍 PARSING OPÉRÉ AVEC SUCCÈS".freeze)
  else
    # log "Le fichier est à jour"
    load
  end
  return true
end #/ parse_if_necessary


# Retourne TRUE s'il faut procéder à l'analyse à nouveau
def out_of_date?
  return true unless File.exists?(data_path)
  return File.stat(data_path).mtime < File.stat(path).mtime
end #/ out_of_date?

def init
  @items = []
  self.current_first_item = 0
end #/ init

# = main =
#
# Méthode principale qui traite le fichier
#
# Traiter le fichier consiste à en faire une entité proximité, c'est-à-dire
# un découpage du texte en paragraphes, lines, mots, locutions, non-mots,
# pour permettre le traitement par l'application.
# Le traitement se fait par stream donc le fichier peut avoir une taille
# conséquente sans problème
def parse

  # Pour savoir le temps que ça prend
  start = Time.now.to_f
  log("Parsing du texte #{path}")

  # Initialisations
  self.init
  Canon.init

  # Préparation du texte
  # --------------------
  # Pour un projet Scrivener, ça consiste à reconstituer tout le
  # texte si nécessaire.
  # La préparation consiste à
  #   effectuer quelques corrections comme les apostrophes courbes.
  # Le texte corrigé est mis dans un fichier portant le même nom que le
  # fichier original mais la marque 'c' est il sera normalement détruit à
  # la fin du processus.
  prepare || return

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || return

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || return

  # On termine en enregistrant la donnée finale
  save

  delai = Time.now.to_f - start
  puts "Délai secondes méthode : #{delai}"

  return true
rescue Exception => e
  log("PROBLÈME EN PARSANT le texte #{path} : #{e.message}#{RC}#{e.backtrace.join(RC)}")
  CWindow.error("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
ensure
  File.delete(corrected_text_path) if File.exists?(corrected_text_path)
end

# Pour "Re-préparer" le texte, c'est-à-dire refaire tout le travail
# de découpage du texte en mots et non-mots, son calcul des proximités
# et l'affichage de son extrait.
# ATTENTION : Cette procédure détruit toutes les transformations déjà
# opérées
def reprepare
  [data_path, main_file_txt, only_mots_path].each do |fpath|
    File.delete(fpath) if File.exists?(fpath)
  end
  parse
end #/ reprepare

def prepare

  # Préparation d'un fichier "full-texte" contenant tout le texte à corriger
  if projet_scrivener?
    prepare_as_projet_scrivener || return
  else # simple copie si pas projet Scrivener
    FileUtils.copy(path, main_file_txt)
  end

  # Préparation d'un fichier corrigé, à partir du fichier full-texte
  prepare_fichier_corriged || return

  # Découpage du fichier corrigé en mots et non-mots
  decoupe_fichier_corriged || return

  return true
end #/ prepare

# Tous les signes, dans le texte, qui vont être considérés comme ne
# constituant pas un mot. Donc les apostrophes et les tirets sont exclus.
DELIMITERS = '  ?!,;:\.…—–=+$¥€«»' # pas de trait d'union, pas d'apostrophe

MOT_NONMOT_REG = /([#{DELIMITERS}]+)?([^#{DELIMITERS}]+)([#{DELIMITERS}]+)/

# On découpe le fichier corrigé en mot et non mots
def decoupe_fichier_corriged
  # On prépare le fichier pour la lémmatisation. Il ne contiendra que
  # les mots, séparés par des espaces simple
  File.delete(only_mots_path) if File.exists?(only_mots_path)
  refonlymots = File.open(only_mots_path,'a')
  # On le fait par paragraphe pour ne pas avoir trop à traiter d'un coup
  File.foreach(corrected_text_path) do |line|
    # log("Phrase originale: #{line.inspect}")
    new_items = traite_line_of_texte(line.strip, refonlymots)
    log("#{new_items.count} ajoutés à itexte.items")
    @items += new_items
    # À la fin de chaque “ligne”, il faut mettre une fin de paragraphe
    @items << NonMot.new(RC, type: 'paragraphe')
  end
  return true
rescue Exception => e
  erreur(e)
  return false
ensure
  refonlymots.close
end #/ decoupe_fichier_corriged

# +refmotscontainer+ Référence au fichier contenant tous les mots,
# dans le mode normal et un fichier virtuel pour les insertions et
# remplacement.
def traite_line_of_texte(line, refmotscontainer)
  new_items = []
  line.scan(MOT_NONMOT_REG).to_a.each_with_index do |item, idx|
    # next if item.nil? # pas de premier délimiteur par exemple
    amorce, mot, nonmot = item # amorce : le tiret, par exemple, pour dialogue
    new_items << NonMot.new(amorce) unless amorce.nil?
    if mot.match?(/#{APO}/) && !MOTS_APOSTROPHE.key?(mot.downcase)
      # log("MOT APOSTROPHE À DÉCOUPER : #{mot.inspect}")
      bouts = mot.split(APO)
      motav = bouts.shift
      motap = bouts.join(APO)
      motav += APO
      new_items << Mot.new(motav)
      new_items << Mot.new(motap)
    elsif mot.match?(/#{TIRET}/) && !MOTS_TIRETS.key?(mot.downcase)
      mots = []
      bouts = mot.split(TIRET)
      mots << bouts.shift
      motap = bouts.join(TIRET)
      if motap.match?(/#{TIRET}/) && !MOTS_TIRETS.key?(motap.downcase)
        mots += motap.split(TIRET)
        mots.last = "#{TIRET}#{mots.last}" # on garde "-il"
      else
        mots << "#{TIRET}#{motap}" # on garde "-il"
      end
      mots.each do |smot|
        new_items << Mot.new(smot)
      end
    else
      new_items << Mot.new(mot)
    end
    # Dans tous les cas, même avec une apostrophe, on écrit le mot tel
    # qu'il est. Parce que lors de la lémmatisation, avec l'apostrophe, il
    # y aura deux mots trouvés alors que "D' aussi" produira "D" (inconnu)
    # et "aussi"
    # On le met en minuscule, car sinon, la lémmatisation ne comprend pas
    # un mot avec capitale au milieu d'une phrase
    refmotscontainer.write("#{mot.downcase}#{SPACE}".freeze)
    new_items << NonMot.new(nonmot)
  end #/scan
  return new_items
end #/ traite_line_of_texte

# On prend le fichier total (contenant tout le texte initial) et on
# le corriger pour qu'il puisse être traité
# Cette opération @produit le fichier self.corrected_text_path
def prepare_fichier_corriged
  File.delete(corrected_text_path) if File.exists?(corrected_text_path)
  reffile = File.open(corrected_text_path,'a')
  begin
    File.foreach(main_file_txt) do |line|
      next if line == RC
      line = line.gsub(/’/, APO)
      reffile.puts line + PARAGRAPHE
    end
    return true
  rescue Exception => e
    erreur(e)
    return false
  ensure
    reffile.close
  end
end #/ prepare_fichier_corriged

# Quand on doit préparer le texte comme un projet scrivener
def prepare_as_projet_scrivener
  log("-> prepare_as_projet_scrivener".freeze)
  ScrivFile.create_table_base_for(Runner.itexte) || return
  projet = Scrivener::Projet.new(path)
  # Préparer le fichier contenant tout le texte si nécessaire
  unless File.exists?(main_file_txt)
    projet.produit_fichier_full_text || return
  end
  return true
rescue Exception => e
  erreur(e)
  return false
end #/ prepare_as_projet_scrivener

# Lémmatiser le texte consiste à le passer par tree-tagger — ce qui prend
# quelques secondes même pour un grand texte — pour ensuite récupérer chaque
# mot et connaitre son canon dans le texte final
def lemmatize
  @lemmatized_file_path = Lemma.parse(only_mots_path)
  # log("Contenu du fichier lemmatized_file_path : #{File.read(lemmatized_file_path)}")
  File.foreach(lemmatized_file_path).with_index do |line, mot_idx_in_lemma|
    next if line.strip.empty?
    traite_lemma_line(line, mot_idx_in_lemma) || break
  end # Fin de boucle sur chaque ligne du fichier de lemmatisation
  return true
end #/ lemmatize

# Traite une ligne de type mot TAB type TAB canon récupérer
# des données de lemmatisation, soit au cours du parse complet du fichier
# à travailler, soit aucun d'une insertion/remplacement
def traite_lemma_line(line, idx)
  mot, type, canon = line.strip.split(TAB)
  Mot.items[idx].type = type
  if mot != Mot.items[idx].content.downcase
    erreur("ERREUR FATALE LES MOTS NE CORRESPONDENT PLUS :")
    imot = Mot.items[idx]
    log("mot:#{mot.inspect}, dans imot: #{imot.content.inspect}, type:#{type.inspect}, canon: #{canon.inspect}")
    return false
  else # quand tout est normal
    Canon.add(Mot.items[idx], canon)
  end
  return true
end #/ traite_lemma_line

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
