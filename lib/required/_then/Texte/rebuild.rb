# encoding: UTF-8
=begin
  Reconstruction du fichier (ou projet Scrivener)
=end
class Texte

# Reconstruction totale du texte.
def rebuild
  if projet_scrivener?
    rebuild_as_projet_scrivener
  else
    rebuild_as_simple_texte
  end
end #/ rebuild


# Reconstruction du texte quand c'est un simple texte (pas un projet
# scrivener). On procède par paquet de 5000 mots pour ne pas trop surcharger
# la mémoire.
def rebuild_as_simple_texte
  File.delete(rebuild_file_path) if File.exists?(rebuild_file_path)
  reffile = File.open(rebuild_file_path,'a')
  # On relève les text-items par 5000 jusqu'à ce qu'il n'y en ait plus
  from_index    = 0
  nombre_titems = 5000
  until (items = get_titems(from_index: from_index, limit:nombre_titems)).empty?
    log("*** Reconstitution du texte, avec les correction. Merci de patienter… (titems #{from_index} à #{from_index + nombre_titems}) ***".freeze, true)
    segment = ""
    items.each { |titem| segment << titem.content_rebuilt }
    reffile.write(segment)
    from_index += nombre_titems
  end
  log("Texte reconstitué avec succès dans #{rebuild_file_path}.#{RC}Taper la commande ':open' pour ouvrir le dossier.".freeze, true)
ensure
  reffile.close if reffile
end #/ rebuild_as_simple_texte



# Reconstruction du projet Scrivener
#
# La procédure est plus compliqué principalement parce que :
#   - plusieurs fichiers différents sont à reconstruire
#   - des marques spéciales sont à ajouter.
#
def rebuild_as_projet_scrivener
  # On boucle sur tous les texte item
  current_file_id = nil
  fileref = nil
  scrivFile = nil
  # Pour le moment, je les prends tous. Par la suite, on verra si
  # ça vaut le coup de les prendre par fichier, ce qui pourrait peut-être
  # accélérer la reconstruction.
  get_titems.each do |titem|

    if titem.file_id && current_file_id != titem.file_id
      # Si on change de fichier Scrivener

      # On mémorise cet identifiant de fichier
      current_file_id = titem.file_id

      # Si un fichier était déjà ouvert (mais comme fileId fonctionne
      # par incrémentation, on pourrait aussi faire fileId > 0)
      unless fileref.nil?
        fileref.close
        fileref = nil
        scrivFile.rebuild_rtf_file
      end
      # On récupère le path du fichier
      file_path = ScrivFile.get_path_by_file_id(titem.file_id)

      scrivFile = ScrivFile.new(projet_scrivener, file_path)
      log("scrivFile: #{scrivFile.path}")

      # Faire une copie du content.rtf initial (le déplacer)
      scrivFile.backup_old_rtf_file || raise("Problème de backup") # TODO REMETTRE

      # Une référence au fichier à écrire
      File.delete(scrivFile.new_txt_file_path) if File.exists?(scrivFile.new_txt_file_path)
      fileref = File.open(scrivFile.new_txt_file_path, 'a')
    end

    # log("J'écris “#{titem.content_rebuilt}” dans ##{scrivFile.id}:#{scrivFile.new_txt_file_path}")
    # C'est dans cette méthode-propriété #content_rebuilt que va être ajouté
    # la balise de début de style ou de fin lorsque c'est un document Scrivener
    fileref.write(titem.content_rebuilt)

  end #/ fin de boucle sur tous les text-items
  fileref.close
  scrivFile.rebuild_rtf_file

  CWindow.log("Projet Scrivener reconstitué avec succès.".freeze)
rescue Exception => e
  erreur(e)
ensure
  fileref.close if fileref
end #/ rebuild_as_projet_scrivener

end #/Texte
