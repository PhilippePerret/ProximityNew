# encoding: UTF-8
=begin
  Module pour Scrivener
=end
module ScrivenerModule
require 'rexml/document'
class Scrivener
class Projet
# ---------------------------------------------------------------------
#
#   INSTANCE Scrivener::Projet
#
# ---------------------------------------------------------------------

attr_reader :itexte

# Le chemin d'accès au fichier .scriv du projet Scrivener
attr_reader :path
# Concernant le fichier .scrivx
attr_reader :pathx, :fichierx, :docxml

# Instanciation
def initialize(path, itexte = nil)
  @path     = path
  @pathx    = File.join(path, "#{File.basename(path)}x".freeze)
  @fichierx = File.new(pathx)
  @docxml   = REXML::Document.new(fichierx)
  @itexte   = itexte
end #/ initialize

def files
  @files || get_all_files
  @files
end #/ files

# Méthode qui va mettre, dans l'ordre, tous les fichiers content.rtf du
# manuscrit
def get_all_files
  @files = []
  draft_folder_binder.elements["Children"].elements.each("BinderItem") do |binder|
    traite_binder(binder, '-')
  end
end #/ get_all_files

# Traitement le binder +binder+ et ajoute ses fichiers et sous-fichiers
# à la liste +liste_fichiers+ (qui servira plus tard à nourrir @files)
# +pref+ est un préfixe qui permet d'afficher la liste des fichiers avec
# une indentation.
def traite_binder(binder, pref)
  binder_uuid   = binder.attributes["UUID"]
  binder_type   = binder.attributes["Type"]
  binder_title  = binder.elements["Title"].text
  # puts "#{pref} Binder #{binder_uuid} #{binder_type} #{binder_title}"
  if binder_type == "Folder"
    binder.elements["Children"].elements.each("BinderItem") do |sbinder,idx|
      traite_binder(sbinder, "#{pref}-")
    end
  else # C'est un texte
    fpath = File.join(files_folder, binder_uuid, 'content.rtf')
    if File.exists?(fpath)
      @files << ScrivFile.new(self, fpath)
    end
  end
end #/ fouille_binder

def draft_folder_binder
  @draft_folder_binder ||= REXML::XPath.first(docxml, "//Binder/BinderItem")
end #/ draft_folder_binder

def name
  @name ||= File.basename(folder) # pour le moment
end #/ name

def files_folder
  @files_folder ||= File.join(folder, 'Files', 'Data')
end #/ files_folder
def folder
  @folder ||= path # File.dirname(path)
end #/ folder
end #/Projet
end #/Scrivener
end
include ScrivenerModule
