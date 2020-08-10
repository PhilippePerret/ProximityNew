# encoding: UTF-8
require 'fileutils'

module Runner
class << self

  def copy(what, params = nil)
    case what
    when 'texte', 'projet'
      # Que ce soit un projet Scrivener ou un texte simple, on peut
      # passer par ici pour faire une copie
      new_nom = params.shift
      return erreur("Il faut donner le nouveau nom en troisième paramètre.") if new_nom.nil?
      if itexte.projet_scrivener?
        copy_texte_as_projet_scrivener(new_nom, params)
      else
        copy_texte_as_texte_simple(new_nom, params)
      end
    else

      erreur("Je ne sais pas copier un “#{what}”. Consulter l'aide (:help).")
    end
  end #/ copy



  # *** Les méthodes de copie ***

  def copy_texte_as_projet_scrivener(new_nom, params)
    # On fait toujours la copie du dossier des proximités
    copy_folder_prox(itexte, new_nom)
    # On copie le dossier/projet Scrivener (.scriv)
    # Rappel : c'est un dossier/une archive
    src_folder = itexte.path
    dst_folder = File.join(itexte.folder, "#{new_nom}.scriv")
    log("COPY FOLDER #{src_folder} -> #{dst_folder}")
    FileUtils.cp_r(src_folder, dst_folder)
    # On change le nom du fichier .scrivx dans .scriv
    src_scrivx = File.join(dst_folder, "#{itexte.affixe}.scrivx")
    dst_scrivx = File.join(dst_folder, "#{new_nom}.scrivx")
    log("RENAME FILE #{src_scrivx} -> #{dst_scrivx}")
    FileUtils.move(src_scrivx, dst_scrivx)
    log("Copie du projet #{itexte.affixe.inspect} vers #{new_nom.inspect} effectuée avec succès.", true)

  rescue Exception => e
    erreur(e)

    return false
  else

    return true
  end #/ copy_texte_as_projet_scrivener

  def copy_texte_as_texte_simple(new_nom, params)
    # On fait toujours la copie du dossier des proximités
    copy_folder_prox(itexte, new_nom) || return
    # On copie le texte
    src_text_file = itexte.path
    dst_text_file = File.join(itexte.folder, "#{new_nom}#{itexte.extension}")
    FileUtils.cp(src_text_file, dst_text_file)
    log("* COPY #{src_text_file} -> #{dst_text_file}")
    log("Copie exécutée avec succès.", true)
  end #/ copy_texte_as_texte_simple

  def copy_folder_prox(itexte, new_nom)
    src_path = itexte.prox_folder
    dst_path = File.join(itexte.folder, "#{new_nom}_prox")
    log("COPY FOLDER #{src_path} -> #{dst_path}")
    FileUtils.cp_r(src_path, dst_path)
  rescue Exception => e
    erreur(e)

    return false
  else

    return true
  end #/ copy_folder_prox

end #/<< self
end #/Module Runner
