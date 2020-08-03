# encoding: UTF-8
=begin
  Module pour Scrivener
=end
module ScrivenerModule
require 'rexml/document'
class Scrivener
class Projet
class << self
  def open(path)
    new(path)
  end #/ open
end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE Scrivener::Projet
#
# ---------------------------------------------------------------------
attr_reader :path, :fichier, :docxml
attr_reader :files # tous les paths des fichiers texte du manuscrit
def initialize(path)
  @path = path
  @fichier = File.new(path)
  @docxml  = REXML::Document.new(fichier)
end #/ initialize

# Méthode qui va mettre, dans l'ordre, tous les fichiers content.rtf du
# manuscrit
def get_all_files
  @files = []
  draft_folder_binder.elements["Children"].elements.each("BinderItem") do |binder|
    traite_binder(binder, '-')
  end
end #/ get_all_files

def traite_binder(binder, pref)
  binder_uuid   = binder.attributes["UUID"]
  binder_type   = binder.attributes["Type"]
  binder_title  = binder.elements["Title"].text
  puts "#{pref} Binder #{binder_uuid} #{binder_type} #{binder_title}"
  if binder_type == "Folder"
    # Quand c'est un dossier
    binder.elements["Children"].elements.each("BinderItem") do |sbinder,idx|
      traite_binder(sbinder, "#{pref}-")
    end
  else
    # C'est un texte
    fpath = File.join(files_folder, binder_uuid, 'content.rtf')
    if File.exists?(fpath)
      @files << fpath
    end
  end
end #/ fouille_binder

def draft_folder_binder
  @draft_folder_binder ||= REXML::XPath.first(docxml, "//Binder/BinderItem")
end #/ draft_folder_binder

def files_folder
  @files_folder ||= File.join(folder, 'Files', 'Data')
end #/ files_folder
def folder
  @folder ||= File.dirname(path)
end #/ folder
end #/Projet
end #/Scrivener
end
