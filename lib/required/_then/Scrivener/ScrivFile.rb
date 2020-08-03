# encoding: UTF-8
require 'sqlite3'
=begin
  Classe ScrivFile
  ----------------
  Elle permet de traiter les fichiers dans les deux sens, c'est-à-dire :
  -> De prendre un fichier RTF de Scrivener et de le transposer en TXT
     en gardant certaines informations.
  <- De prendre le fichier TXT travaillé avec les proximités et de le
     repasser en fichier RTF pour Scrivener.
=end
class ScrivFile
class << self
  def get_new_id
    @lastId ||= 0
    @lastId += 1
  end #/ get_new_id
end # /<< self
attr_reader :id, :itexte, :path

# Instanciation, à partir du path
def initialize(itexte, path)
  @itexte = itexte # L'instance Runner::Texte du projet Scrivener dans ProximityNew
  @path   = path
  @id     = self.class.get_new_id
end #/ initialize

# On fabrique le code TXT du fichier
def build_txt_file
  # `textutil -format rtf -convert txt -stdout "#{path}"`
  `textutil -format rtf -convert txt -output "#{txt_file_path}" "#{path}"`
  # Un pied de page pour connaitre le fichier
  File.open(txt_file_path,'a'){|f| f.write "#{RC}[F#{id}]#{RC}".freeze}
end #/ build_txt_file

# Construction du nouveau fichier de text qui devra servir pour
# la reconstruction du fichier RTF
def build_new_txt_file

end #/ build_new_txt_file

# Pour reconstruire le fichier RTF
def rebuild_rtf_file
  `textutil -format txt -convert rtf -output "#{rtf_new_file_path}" "#{txt_new_file_path}" > `
  # On retire l'entête actuel
  # TODO
  # On remet d'entête original
  # TODO
  # On corrige les balise <::[0-9]>> et <!::[0-9]>
  # TODO
end #/ rebuild_rtf_file

# Méthode permettant de mettre de côté le fichier RTF Scrivener courant
def backup_old_rtf_file
  # TODO
  FileUtil.move(path, original_backup_path)
end #/ backup_old_rtf_file

# Chemin d'accès au fichier TXT contenant le texte du fichier courant
# seulement (qui sera assemblé ensuite aux autres)
def txt_file_path
  @txt_file_path ||= File.join(TODO)
end #/ txt_file_path

def txt_new_file_path
  @txt_new_file_path ||= File.join(TODO)
end #/ txt_new_file_path

# Chemin d'accès au fichier RTF reconstruit d'après le fichier TXT
# travaillé dans ProximityNew
def rtf_new_file_path
  @rtf_new_file_path ||= File.join(TODO)
end #/ rtf_new_file_path

# Récupération de l'entête et enregistrement dans la base
def save_header

end #/ save_header
# On récupère l'entête enregistrée
def load_header
  headerref = File.open(original_header_path,'a')
  File.foreach(path) do |line|
    headerref.puts(line)
    break if line == RC
  end
ensure
  headerref.close
end #/ load_header

def original_header_path
  @original_header_path ||= File.join(folder, 'original-header.txt')
end #/ original_header_path

# Chemin d'accès au fichier RTF original, celui qui sert dans le projet
# Scrivener. Il sera conservé sous ce nom, dans son dossier original, pour
# pouvoir éventuellement le recouvrer.
def original_backup_path
  @original_backup_path ||= File.join(folder,"#{affixe}-backup.rtf")
end #/ original_backup_path


# Dossier du fichier dans le projet Scrivener
def folder
  @folder ||= File.dirname(path)
end #/ folder

# Affixe du fichier (mais en fait, c'est toujours 'content.rtf')
def affixe
  @affixe ||= File.basename(path, File.extname(path))
end #/ affixe
end #/ScrivFile
