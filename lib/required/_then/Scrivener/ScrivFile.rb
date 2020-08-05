# encoding: UTF-8
require 'fileutils'
require 'sqlite3'
=begin
  Classe ScrivFile
  ----------------
  Elle permet de traiter les fichiers dans les deux sens, c'est-à-dire :
  -> De prendre un fichier RTF de Scrivener et de le transposer en TXT
     en gardant certaines informations.
  <- De prendre le fichier TXT travaillé avec les proximités et de le
     repasser en fichier RTF pour Scrivener.

  * Utiliser d'abord ScrivFile.create_table_base_for(itexte) pour créer
    la table de données qui va contenir les données pour les fichiers.
=end
class ScrivFile
class << self

  # Crée la table qui va recevoir les fichiers du projet Scrivener
  def create_table_base_for(itexte)
    log("-> create_table_base_for".freeze)
    @db ||= begin
      dbname = itexte.db_path
      SQLite3::Database.open(dbname)
    end
    begin
      db.execute('DROP TABLE IF EXISTS `scrivener_files`'.freeze)
      db.execute('CREATE TABLE `scrivener_files` (Id INT NOT NULL, Uuid VARCHAR NOT NULL, Path TEXT NOT NULL, Header TEXT)')
      return true
    rescue SQLite3::Exception => e
      erreur(e)
      return false
    end
  end #/ create_table_base_for

  def save(sfile)
    begin
      db.execute("INSERT INTO scrivener_files (Id, Path, Uuid) VALUES (#{sfile.id}, #{sfile.path.inspect}, #{sfile.uuid.inspect})".freeze)
    rescue SQLite3::Exception => e
      erreur(e)
    end
  end #/ save

  def db
    @db ||= begin
      SQLite3::Database.open(Runner.itexte.db_path)
    end
  end #/ db

  def get_new_id
    @lastId ||= 0
    @lastId += 1
  end #/ get_new_id
end # /<< self
attr_reader :id, :projet, :path, :itexte

# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

# Instanciation, à partir du path
def initialize(projet, path)
  @projet = projet # Le projet Scrivener
  @path   = path    # Le chemin au fichier content.rtf
  @id     = self.class.get_new_id
  @itexte = Runner.itexte
  save
end #/ initialize

# On enregistre les données du fichier dans la base, c'est-à-dire,
# principalement, la relation entre l'identifiant court (incrémentation à
# partir de 1) et l'UUID dans Scrivener.
def save
  self.class.save(self)
end #/ save

# Le fichier RTF doit être "préparé", c'est-à-dire transformé en un
# fichier simple texte qui pourra être traité par NewProximity
def prepare
  build_txt_file || return
  remplace_balises_styles
  return true
end #/ prepare

# Méthode qui remplace les balises <$Scr_Cs([0-9]+)> par une marque
# XSCRIVxxx<mot> pour le traitement dans New Proximity
def remplace_balises_styles
  temp = "#{txt_file_path}.prov"
  FileUtils.move(txt_file_path, temp)
  ref = File.open(txt_file_path,'a')
  File.foreach(temp) do |line|
    line.gsub!(/<\$Scr_Cs::([0-9]+)>(.*?)<\!\$Scr_Cs::(\1)>/){
      nomb    = $1.to_s.rjust(3,'O').freeze # vraiment des "oh" par zéro
      mots    = $2.freeze
      balIN   = "XSCRIVSTART#{nomb}".freeze
      balOUT  = "XSCRIVEND#{nomb}".freeze
      balIN + mots + SPACE + balOUT # pas d'espace pour le premier !
    }
    ref.puts(line)
  end
  File.delete(temp)
ensure
  ref.close if ref
end #/ remplace_balises_styles


# On fabrique le code TXT du fichier
def build_txt_file
  # `textutil -format rtf -convert txt -stdout "#{path}"`
  `textutil -format rtf -convert txt -stdout "#{path}" >> "#{txt_file_path}"`
  return true
rescue Exception => e
  erreur(e)
  return false
end #/ build_txt_file

# Balise pour mettre avant et après le texte dans le fichier contenant tout
# le texte. Elle a une longueur fixe "[-File-XXXX-/]" et "[/-File-XXXX-]"
# Donc de 14 caractères
#
def balise
  @balise ||= "-File-#{id.to_s.rjust(4,'0')}-".freeze
end #/ balise

# Construction du nouveau fichier de text qui devra servir pour
# la reconstruction du fichier RTF
def build_new_txt_file
  # Je pense que c'est le traitement du fichier principal qui va faire
  # ça en redirigeant sa sortie vers le fichier new_txt_file_path
  raise("La méthode build_new_txt_file est à implémenter (#{__FILE__}:#{__LINE__})")
end #/ build_new_txt_file

# Pour reconstruire le fichier RTF
def rebuild_rtf_file
  # On transforme le nouveau fichier texte en fichier RTF
  `textutil -format txt -convert rtf -output "#{rtf_new_file_path}" "#{new_txt_file_path}" > `
  raise("La méthode rebuild_rtf_file est à implémenter (#{__FILE__}:#{__LINE__})")
  # On retire l'entête actuel
  # TODO
  # On remet d'entête original
  # TODO
  # On corrige les balise <::[0-9]>> et <!::[0-9]>
  # TODO
end #/ rebuild_rtf_file

# Méthode permettant de mettre de côté le fichier RTF Scrivener courant
def backup_old_rtf_file
  FileUtil.move(path, original_backup_path)
end #/ backup_old_rtf_file

# Chemin d'accès au fichier TXT contenant le texte du fichier courant
# seulement (qui sera assemblé ensuite aux autres)
def txt_file_path
  @txt_file_path ||= File.join(folder,'content_txt_for_prox.txt'.freeze)
end #/ txt_file_path
alias :main_file_txt :txt_file_path # pour la concordance de nom dans NewProx

# Chemin d'accès au fichier corrigé (quelques corrections comme les apostrophes
# courbes) pour un traitement optimum dans NewProximity
def corrected_text_path
  @corrected_text_path ||= File.join(folder,'content_txt_for_prox_c.txt'.freeze)
end #/ corrected_text_path

# Chemin d'accès au fichier qui ne va contenir que les mots du texte
def only_mots_path
  @only_mots_path ||= File.join(folder,'only_mots.txt'.freeze)
end #/ only_mots_path

def new_txt_file_path
  @new_txt_file_path ||= File.join(folder,'new_txt_from_prox.txt'.freeze)
end #/ new_txt_file_path

# Chemin d'accès au fichier RTF reconstruit d'après le fichier TXT
# travaillé dans ProximityNew
def rtf_new_file_path
  @rtf_new_file_path ||= File.join(folder,'new_rtf_from_prox.txt'.freeze)
end #/ rtf_new_file_path

# Récupération de l'entête et enregistrement dans la base
def save_header
  headerref = File.open(original_header_path,'a')
  File.foreach(path) do |line|
    headerref.puts(line)
    break if line == RC
  end
ensure
  headerref.close
end #/ save_header

# On récupère l'entête enregistrée
def load_header
  File.read(original_header_path)
end #/ load_header

def original_header_path
  @original_header_path ||= File.join(folder, 'original-header.txt')
end #/ original_header_path

# Chemin d'accès au fichier RTF original, celui qui sert dans le projet
# Scrivener. Il sera conservé sous ce nom, dans son dossier original, pour
# pouvoir éventuellement le recouvrer.
def original_backup_path
  @original_backup_path ||= File.join(folder,"#{affixe}-backup-#{Time.now.strftime('%d-%m-%Y')}.rtf")
end #/ original_backup_path


# UUID du fichier (c'est le nom du dossier qui contient le fichier content.rtf)
def uuid
  @uuid ||= File.basename(folder)
end #/ uuid

# Dossier du fichier dans le projet Scrivener
def folder
  @folder ||= File.dirname(path)
end #/ folder

# Affixe du fichier (mais en fait, c'est toujours 'content.rtf')
def affixe
  @affixe ||= File.basename(path, File.extname(path))
end #/ affixe
end #/ScrivFile
