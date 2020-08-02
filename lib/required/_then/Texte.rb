# encoding: UTF-8
TAB = "\t".freeze unless defined?(TAB)
RC = "\n".freeze  unless defined?(RC)
APO = "'".freeze  unless defined?(APO)
SPACE = ' '.freeze unless defined?(SPACE)
EMPTY_STRING = ''.freeze unless defined?(EMPTY_STRING)

class Texte
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

def save
  data = {
    items: items,
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
PARAGRAPHE = '__PARAGRAPHE__'.freeze
def parse

  # Pour savoir le temps que ça prend
  start = Time.now.to_f

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
  File.foreach(lemmatized_file_path) do |line|
    mot, type, canon = line.strip.split(TAB)
    if mot == PARAGRAPHE
      # Marque de nouveau paragraphe
      # On crée un nouveau paragraphe avec les éléments
      @items << NonMot.create([RC, 'paragraphe'], cur_offset)
      cur_offset += 2
    elsif type == 'SENT'
      # Est-ce une fin de phrase ?
      @items << NonMot.create([mot,type], cur_offset)
      cur_offset += mot.length
    else
      @items << Mot.create([mot,type,canon], cur_offset)
      cur_offset += mot.length + 1
    end
  end

  # *** attributions ***

end #/ parse

# ---------------------------------------------------------------------
#
#   CHEMINS
#
# ---------------------------------------------------------------------

def data_path
  @data_path ||= File.join(folder,"#{affixe}-prox.data.msh")
end #/ data_path

def corrected_text_path
  @corrected_text_path ||= File.join(folder,"#{affixe}_c#{extension}".freeze)
end #/ corrected_text_path


def folder
  @folder ||= File.dirname(path)
end #/ folder
def affixe
  @affixe ||= File.basename(path, extension)
end #/ affixe
def extension
  @extension ||= File.extname(path)
end #/ extension

# Pour lire le contenu du fichier, mais ça ne devrait pas être nécessaire
# ni utile. Si le fichier est gros, ça peut même être maladroit.
def content
  @content ||= File.read(path).force_encoding(Encoding::ASCII_8BIT).force_encoding(Encoding::UTF_8)
end #/ content
end #/Texte
