# encoding: UTF-8

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
end #/ initialize

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
  while item = items[idx += 1]
    # Si le décalage du mot change et que son canon n'est pas encore à
    # actualiser, il faut l'enregistrer pour l'actualiser
    if item.offset != offset && !canons_to_update.key?(item.canon)
      canons_to_update.merge!(item.canon => item.icanon)
    end
    item.offset = offset
    item.index  = idx
    offset += item.length + 1 # approximatif car on n'ajoute pas toujours 1 espace
    nb += 1
  end

  # Actualisation des canons
  erreurs = []
  canons_to_update.each do |canon, icanon|
    if icanon.nil?
      erreurs << "ERREUR: Le canon #{canon.inspect} est nul"
    else
      icanon.update
    end
  end
  unless erreurs.empty?
    CWindow.error("Une erreur est survenue avec les canons. Quitter et consulter le journal.")
    log("### ERREUR UPDATE CANON ####{RC}#{erreurs.join(RC)}")
  end

  end_time = Time.now.to_f
  CWindow.log("Fin du recalcul. Quitter et voir le temps")

  log("Durée du recomptage de #{nb} items : #{end_time - start_time}")
end #/ recompte

# On doit forcer la ré-analyse du texte
def reproximitize
  CWindow.logWind.write('Ré-analyse du texte…')
  File.delete(data_path) if File.exists?(data_path)
  parse
  CWindow.logWind.write('Texte analysé avec succès.')
end #/ reproximitize

def save
  data = {
    items: items,
    canons:  Canon.items_as_hash,
    path:  path,
    current_first_item: current_first_item,
    updated_at: Time.now,
    created_at: Time.now
  }
  File.open(data_path,'wb'){|f| Marshal.dump(data,f)}
end #/ save

def load
  @data = Marshal.load(File.read(data_path))
  @items = @data[:items]
  @current_first_item = @data[:current_first_item]
  Canon.items_as_hash = @data[:canons]
end #/ load

# Il faut voir s'il est nécessaire de parser le fichier. C'est nécessaire
# si le fichier d'analyse n'existe pas ou s'il est plus vieux que le
# nouveau texte.
def parse_if_necessary
  if out_of_date?
    # puts "Le fichier doit être actualisé"
    parse
  else
    load
    # puts "Les données sont à jour"
  end
end #/ parse_if_necessary


# Retourne TRUE s'il faut procéder à l'analyse à nouveau
def out_of_date?
  return true unless File.exists?(data_path)
  return File.stat(data_path).mtime < File.stat(path).mtime
end #/ out_of_date?


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
  @items = []
  Canon.init
  self.current_first_item = 0

  # Préparation du texte. La préparation consiste à marquer les paragraphes
  # et à établir quelques corrections comme les apostrophes courbes.
  # Le texte corrigé est mis dans un fichier portant le même nom que le
  # fichier original mais la marque 'c' est il sera normalement détruit à
  # la fin du processus.
  prepare

  # On le fait ensuite en lemmatisant d'abord tout le fichier
  lemmatize

  # Et on dispatche en mots et non mots
  dispatche

  # On termine en enregistrant la donnée finale
  save

  delai = Time.now.to_f - start
  puts "Délai secondes méthode : #{delai}"

rescue Exception => e
  log("PROBLÈME EN PARSANT le texte #{path} : #{e.message}#{RC}#{e.backtrace.join(RC)}")
  CWindow.error("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
ensure
  File.delete(corrected_text_path) if File.exists?(corrected_text_path)
end


def prepare
  File.delete(corrected_text_path) if File.exists?(corrected_text_path)
  reffile = File.open(corrected_text_path,'a')
  begin
    File.foreach(path) do |line|
      next if line == RC
      line = line.gsub(/’/, APO)
      reffile.puts line + PARAGRAPHE
    end
  ensure
    reffile.close
  end
end #/ prepare

# Lémmatiser le texte consiste à le passer par tree-tagger — ce qui prend
# quelques secondes même pour un grand texte — pour ensuite récupérer chaque
# mot et connaitre son canon dans le texte final (car le problème, c'est que
# cette lemmatisation fait perdre la position exacte du mot, donc on ne pourrait
# par reconstituer le texte exactement)
# NOTE Mais pour le moment on va quand même se servir de ça
def lemmatize
  @lemmatized_file_path = Lemma.parse(corrected_text_path)
end #/ lemmatize

# Ici, les données lemmatisées sont distribuées dans les paragraphes, les
# lignes, les mots et les non-mots.
def dispatche
  # Pour garder l'offset courant
  cur_offset = 0
  cur_index  = 0
  File.foreach(lemmatized_file_path) do |line|
    instance = TexteItem.lemma_to_instance(line,cur_offset,cur_index)
    @items << instance # Mot ou NonMot
    cur_offset += if instance.content == PARAGRAPHE # Marque de paragraphe
                    2
                  elsif instance.ponctuation?
                    instance.content.length
                  else
                    instance.length + 1
                  end
    # Index suivant
    cur_index += 1
  end

  # *** attributions ***

end #/ parse

# ---------------------------------------------------------------------
#
#   CHEMINS
#
# ---------------------------------------------------------------------
def config_path
  @config_path ||= File.join(prox_folder,'config.json')
end #/ config_path
def config_default_data
  {
    last_first_index: 0
  }
end #/ config_default_data

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
