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


def rebuild_as_projet_scrivener
  # On boucle sur tous les texte item
  current_file_id = nil
  file_ref = nil
  scrivFile = nil
  items.each do |titem|

    if titem.file_id && current_file_id != titem.file_id
      # Si on change de fichier Scrivener

      # On mémorise cet identifiant de fichier
      current_file_id = titem.file_id

      # Si un fichier était déjà ouvert (mais comme fileId fonctionne
      # par incrémentation, on pourrait aussi faire fileId > 0)
      unless file_ref.nil?
        file_ref.close
        file_ref = nil
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
      file_ref = File.open(scrivFile.new_txt_file_path, 'a')
    end

    # log("J'écris “#{titem.content_rebuilt}” dans ##{scrivFile.id}:#{scrivFile.new_txt_file_path}")
    file_ref.write(titem.content_rebuilt)

  end #/ fin de boucle sur tous les text-items
  file_ref.close
  scrivFile.rebuild_rtf_file

  CWindow.log("Projet Scrivener reconstitué avec succès.".freeze)
rescue Exception => e
  erreur(e)
ensure
  file_ref.close if file_ref
end #/ rebuild_as_projet_scrivener

def rebuild_as_simple_texte
  File.delete(rebuild_file_path) if File.exists?(rebuild_file_path)
  File.open(rebuild_file_path,'wb') do |f|
    items.each { |titem| f.write(titem.content_rebuilt) }
  end
  CWindow.log("Texte reconstitué avec succès.".freeze)
end #/ rebuild_as_simple_texte

end #/Texte
