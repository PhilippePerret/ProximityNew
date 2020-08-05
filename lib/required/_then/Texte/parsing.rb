# encoding: UTF-8
=begin
  Méthode de parsing du texte
=end

# Tous les signes, dans le texte, qui vont être considérés comme ne
# constituant pas un mot. Donc les apostrophes et les tirets sont exclus.
WORD_DELIMITERS = '  ?!,;:\.…—–=+$¥€«»\[\]\(\)<>“”' # pas de trait d'union, pas d'apostrophe

MOT_NONMOT_REG = /([#{WORD_DELIMITERS}]+)?([^#{WORD_DELIMITERS}]+)([#{WORD_DELIMITERS}]+)/


# Pour les erreurs à enregistrer
ParsingError = Struct.new(:message, :where)

class Texte
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

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
  log("*** Parsing du texte #{path}")

  # Initialisations
  self.init
  Canon.init

  # Préparation du texte
  # --------------------
  # La préparation consiste à effectuer quelques corrections comme les
  # apostrophes courbes.
  # Le texte corrigé est mis dans un fichier portant le même nom que le
  # fichier original avec la marque 'c' est il sera normalement détruit à
  # la fin du processus.
  prepare || return

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || return

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || return

  # On termine en enregistrant la donnée finale. Cette donnée, ce
  # sont tous les mots, les canons, ainsi que les préférences sur
  # le texte.
  save

  delai = Time.now.to_f - start

  fin_parsing(path, delai)

  return true

rescue Exception => e
  log("PROBLÈME EN PARSANT le texte #{path} : #{e.message}#{RC}#{e.backtrace.join(RC)}")
  CWindow.error("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
ensure
  File.delete(corrected_text_path) if File.exists?(corrected_text_path)
end

# = main =
#
# Parsing d'un projet scrivener.
# Ce parsing est différent dans le sens où plusieurs fichiers texte vont
# permettre de constituer le Runner.itexte final.
def parse_projet_scrivener(projet)

  # Pour savoir le temps que ça prend
  start = Time.now.to_f
  log("*** Parsing du projet scrivener #{projet.path}")
  CWindow.log("Parsing du projet scrivener #{projet.name}. Merci de patienter…")

  # Initialisations
  self.init
  Canon.init
  Mot.init

  # Prépare le projet Scrivener et, notamment, la base de données
  # où seront consignées les informations sur les fichiers.
  prepare_as_projet_scrivener

  # Effacement des fichiers de parsing.
  erase_parsing_files

  log("Nombre de fichiers à traiter : #{projet.files.count}")
  projet.files.each do |scrivfile| # instance ScrivFile

    log("** Traitement du fichier scrivener #{scrivfile.uuid}")

    # Effacement des fichiers qui se trouvent peut-être dans le
    # dossier du fichier Scrivener courant à traiter.
    erase_parsing_files(scrivfile)

    # Préparation du
    # --------------------
    # La préparation consiste à effectuer quelques corrections comme les
    # apostrophes courbes.
    # Le texte corrigé est mis dans un fichier portant le même nom que le
    # fichier original avec la marque 'c' est il sera normalement détruit à
    # la fin du processus.
    prepare(scrivfile) || return

  end #/ fin de boucle sur chaque fichier du projet Scrivener

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || return

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || return

  # On termine en enregistrant la donnée finale. Cette donnée, ce
  # sont tous les mots, les canons, ainsi que les préférences sur
  # le texte.
  save

  delai = Time.now.to_f - start

  fin_parsing("PROJET SCRIVENER #{File.basename(projet.path)}", delai)

  return true

rescue Exception => e
  log("PROBLÈME EN PARSANT le projet scrivener #{projet.path} : #{e.message}#{RC}#{e.backtrace.join(RC)}")
  CWindow.error("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
end #/ parse_projet_scrivener

def init
  @items = []
  @parsing_errors = []
  self.current_first_item = 0
  erase_parsing_files
end #/ init

def add_parsing_error(error)
  Errorer << error.message
  log("ERREUR PARSING: #{error.message}")
  @parsing_errors << error
end #/ add_parsing_error

def fin_parsing(what, duration)
  unless @parsing_errors.empty?
    erreur("Des erreurs sont survenues (#{@parsing_errors.count}). Consulter le fichier errors.log")
  else
    log("👍 PARSING DU #{what} OPÉRÉ AVEC SUCCÈS".freeze)
    log("   (durée de l'opération : #{duration})#{RC*2}".freeze)
  end

end #/ fin_parsing

# Eraser les fichiers
# -------------------
# La méthode s'appelle à deux endroits différents quand on traite un
# projet Scrivener : au commencement du parsing, pour détruire les fichiers
# généraux et avant le traitement de chaque fichier pour détruire les
# main_file_txt et les refaire.
def erase_parsing_files(scrivfile = nil)
  proprio = scrivfile || self
  file_list = []
  if scrivfile.nil?
    file_list << only_mots_path
    file_list << data_path
  else
    file_list << proprio.main_file_txt
  end
  file_list.each do |fpath|
    File.delete(fpath) if File.exists?(fpath)
  end
end #/ erase_parsing_files

# Il faut voir s'il est nécessaire de parser le fichier. C'est nécessaire
# si le fichier d'analyse n'existe pas ou s'il est plus vieux que le
# nouveau texte.
def parse_if_necessary(projetscriv = nil)
  log("-> parse_if_necessary")
  if out_of_date? # Le fichier doit être actualisé
    log("= Le fichier doit être actualisé#{" (c'est un projet Scrivener)" if projet_scrivener?}")
    if projet_scrivener?
      parse_projet_scrivener(projetscriv)
    else
      parse
    end || return
  else # quand le fichier est à jour
    load
  end
  return true
end #/ parse_if_necessary


def prepare(sfile = nil)
  if projet_scrivener?
    file_to_correct = sfile.main_file_txt
    file_corrected  = sfile.corrected_text_path
    # Il faut préparer le fichier Scrivener
    sfile.prepare
  else # simple copie du fichier texte, si pas projet Scrivener
    FileUtils.copy(path, main_file_txt)
    file_to_correct = main_file_txt
    file_corrected  = corrected_text_path
  end

  # Préparation d'un fichier corrigé, à partir du fichier full-texte
  prepare_fichier_corriged(file_to_correct, file_corrected) || return

  # Découpage du fichier corrigé en mots et non-mots
  decoupe_fichier_corriged(sfile) || return

  return true
end #/ prepare

# On découpe le fichier corrigé en mot et non mots
# +file_corrected+ est le chemin d'accès au fichier mots corrigé, pour
# un texte normal, et un des fichiers du projet.
def decoupe_fichier_corriged(scrivfile = nil)
  proprio = scrivfile || self
  file_corrected = proprio.corrected_text_path
  refonlymots = File.open(only_mots_path,'a')
  # On le fait par paragraphe pour ne pas avoir trop à traiter d'un coup
  File.foreach(file_corrected) do |line|
    next if line.strip.empty?
    new_items = traite_line_of_texte(line.strip, refonlymots)
    if new_items.empty?
      log("# Aucun item ajouté avec la line #{line.inspect}".freeze)
      next
    else
      log("Items ajoutés à itexte.items : #{new_items.count}".freeze)
    end
    new_items.each { |titem| titem.file_id = scrivfile.id } unless scrivfile.nil?
    @items += new_items
    # À la fin de chaque “ligne”, il faut mettre une fin de paragraphe
    @items << NonMot.new(RC, type: 'paragraphe', file_id: scrivfile&.id)
  end
  # On retire toujours les derniers retours charriot
  @items.pop while @items.last.content == RC
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
  mark_style = nil # pour les projets Scrivener
  line.scan(MOT_NONMOT_REG).to_a.each_with_index do |item, idx|
    # next if item.nil? # pas de premier délimiteur par exemple
    amorce, mot, nonmot = item # amorce : le tiret, par exemple, pour dialogue
    new_items << NonMot.new(amorce) unless amorce.nil?

    if mot.start_with?('XSCRIVSTART')
      # C'est le début d'une marque de style dans un projet Scrivener
      # Note : cette marque est collé au mot, il faut donc poursuivre
      # le traitement
      mark_style = mot[11...14].gsub(/O/,'').to_i
      mot = mot[14..-1]
    elsif mot.start_with?('XSCRIVEND')
      # Cette marque n'est pas collé au dernier mot, il faut
      # arrêter le traitement après son enregistrement dans le
      # dernier mot traité.
      new_items.last.mark_scrivener_end = mot[9...12].gsub(/O/,'').to_i
      next # rien à faire par la suite, on passe au suivant
    end

    if mot.match?(/#{TIRET}/) || mot.match?(/#{APO}/)
      traite_mot_special(mot).each do |titem|
        # log("Mot spécial ajouté : #{titem.inspect}")
        if mark_style
          titem.mark_scrivener_start = mark_style
          mark_style = nil
        end
        new_items << titem
        if titem.is_a?(Mot)
          sep = titem.is_colled ? EMPTY_STRING : SPACE
          refmotscontainer.write("#{titem.content.downcase}#{sep}".freeze)
        end
      end
    else
      titem = Mot.new(mot)
      if mark_style
        titem.mark_scrivener_start = mark_style
        mark_style = nil
      end
      new_items << titem
      refmotscontainer.write("#{mot.downcase}#{SPACE}".freeze)
    end
    titem = NonMot.new(nonmot)
    if mark_style
      titem.mark_scrivener_start = mark_style
      mark_style = nil
    end
    new_items << titem
  end #/scan
  return new_items
end #/ traite_line_of_texte

def traite_mot_special(mot)
  mots = []
  if mot.match?(/#{APO}/)
    if MOTS_APOSTROPHE.key?(mot.downcase)
      return [Mot.new(mot)]
    else
      # Ce n'est pas un mot comme aujourd'hui, connu pour avoir une
      # apostrophe. S'il n'y qu'une seule apostrophe, on retourne deux
      bouts = mot.split(APO)
      bouts_debugged = bouts.inspect
      firstmot = Mot.new(bouts[0] << APO).tap { |m| m.is_colled = true }
      if bouts.count == 1
        # Ça arrive par exemple avec le "L" dans "L’« autre monde »" à
        # cause des chevrons. Dans ce cas, bouts = ["L"]
        return [firstmot]
      elsif bouts.count == 2
        return [firstmot, Mot.new(bouts[1])]
      end
      # S'il y a deux apostrophe (maximum) on regarde si le second
      # mot est un mot connu, comme dans "plus qu'aujourd'hui"
      # Sinon, on renvoie les trois mots
      bouts.shift
      deuxi = bouts.join(APO)
      if MOTS_APOSTROPHE.key?(deuxi.downcase)
        return [firstmot, Mot.new(deuxi)]
      else
        motsuiv = if bouts[0].nil?
          add_parsing_error(ParsingError.new("bouts[0] ne devrait pas pouvoir être nil dans #{mot.inspect} (bouts: #{bouts_debugged}). Ça devrait être le troisième mot.", "#{__FILE__}:#{__LINE__}"))
          Mot.new(APO)
        else
          Mot.new(bouts[0] << APO)
        end
        motsuiv.is_colled = true
        return [firstmot, motsuiv, Mot.new(bouts[1])]
      end
    end
  end

  if mot.match?(/#{TIRET}/)
    if MOTS_TIRETS.key?(mot.downcase)
      # Un mot tiret connu, comme "peut-être" ou "grand-chose"
      # cf. la liste dans constantes/proximites.rb
      return [Mot.new(mot)]
    else
      # Ce n'est pas un mot comme peut-être, connu pour avoir une
      # apostrophe. S'il n'y qu'un seul tiret, on retourne les deux
      # mots avec un tiret ajouté en non mot
      bouts = mot.split(TIRET)
      if bouts.count == 2
        return [Mot.new(bouts[0]), NonMot.new(TIRET, type:'PUN'), Mot.new(bouts[1])]
      end
      # S'il y a deux tirets (maximum) on regarde si le second
      # mot est un mot-tiret connu, comme dans "arrière-grand-père" (c'est
      # juste un exemple car "arrière-grand-père" est un mot-tiret connu)
      # Sinon, on renvoie les trois mots en mettant entre un tiret
      first = bouts.shift
      deuxi = bouts.join(TIRET)
      if MOTS_TIRETS.key?(deuxi.downcase)
        return [Mot.new(first), NonMot.new(TIRET, type:'PUN'), Mot.new(deuxi)]
      else
        return [
          Mot.new(first),
          NonMot.new(TIRET, type:'PUN'),
          Mot.new(bouts[0]),
          NonMot.new(TIRET, type:'PUN'),
          Mot.new(bouts[1])
        ]
      end
    end
  end


  # if mot.match?(/#{APO}/)
  #   if MOTS_APOSTROPHE.key?(mot.downcase)
  #     # mots << mot
  #     mots << Mot.new(mot)
  #   else
  #     # log("MOT APOSTROPHE À DÉCOUPER : #{mot.inspect}")
  #     bouts = mot.split(APO)
  #     if bouts.count == 2
  #       # <= OK, seulement une apostrophe
  #       # => on prend les deux mots séparément (en remettant
  #       #    l'apostrophe au premier mot)
  #       # bouts[0] << APO
  #       # mots = bouts
  #       mots << Mot.new(bouts[0] << APO)
  #       mots << Mot.new(bouts[1])
  #     else # plus d'une apostrophe => chaque double doit être traité
  #       i = 0
  #       last_indice = bouts.count - 1
  #       while i < last_indice
  #         double = bouts[i]+APO+bouts[i+1]
  #         if MOTS_APOSTROPHE.key?(double.downcase)
  #           # mots << double
  #           mots << Mot.new(double)
  #           i += 1
  #         else
  #           # bouts[i] << APO unless i == last_indice
  #           # mots << bouts[i]
  #           mots << NonMot.new(APO, type: 'APO')
  #           mots << Mot.new(bouts[i])
  #         end
  #         i += 1
  #         if i == last_indice
  #           # mots << bouts[i]
  #           mots << NonMot.new(APO, type: 'APO')
  #           mots << Mot.new(bouts[i])
  #           break
  #         end
  #       end
  #       log("mots apostrophes à la fin : #{mots.inspect}")
  #     end
  #   end
  # end
  if mot.match?(/#{TIRET}/)
    if MOTS_TIRETS.key?(mot.downcase)
      # mots << mot
      mots << Mot.new(mot)
    else
      bouts = mot.split(TIRET)
      if bouts.count == 2
        # <= seulement un tiret
        # => on prend les deux mots séparément (en remettant le tiret au
        #    second mot)
        # bouts[1].prepend(TIRET)
        # mots = bouts
        mots << Mot.new(bouts[0])
        mots << NonMot.new(TIRET, type:'TIRET')
        mots << Mot.new(bouts[1])
      else
        # Plus d'un tiret
        # => on teste par paire
        i = 0
        last_indice = bouts.count - 1
        while i < last_indice
          double = bouts[i]+TIRET+bouts[i+1]
          if MOTS_TIRETS.key?(double.downcase)
            # mots << double
            mots << Mot.new(double)
            i += 1
          else
            # bouts[i].prepend(TIRET) unless i == 0
            # mots << bouts[i]
            mots << NonMot.new(TIRET, type:'TIRET') unless i == 0
            mots << Mot.new(bouts[i])
          end
          i += 1
          if i == last_indice
            # mots << bouts[i]
            mots << NonMot.new(TIRET, type:'TIRET')
            mots << Mot.new(bouts[i])
            break
          end
        end
        log("mots à la fin : #{mots.inspect}")
      end
    end
  end
  return mots
end #/ traite_mot_special

# On prend le fichier texte (contenant tout le texte initial ou le texte
# du fichier d'un projet Scrivener) et on le corrige pour qu'il puisse être
# traité. Cette opération @produit le fichier +file_corrected_path+
def prepare_fichier_corriged(file_to_correct, file_corrected_path)
  File.delete(file_corrected_path) if File.exists?(file_corrected_path)
  reffile = File.open(file_corrected_path,'a')
  begin
    File.foreach(file_to_correct) do |line|
      next if line == RC
      line = line.gsub(/’/, APO)
      reffile.puts line
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
  return true
rescue Exception => e
  erreur(e)
  return false
end #/ prepare_as_projet_scrivener

# Lémmatiser le texte consiste à le passer par tree-tagger — ce qui prend
# quelques secondes même pour un grand texte — pour ensuite récupérer chaque
# mot et connaitre son canon dans le texte final
#
# Pour savoir de quel mot il s'agit, on se sert de l'index dans Mot.items
# et de l'index dans le fichier only_mots_path. Cet index correspond.
def lemmatize
  lemma_file_path = Lemma.parse(only_mots_path)
  # log("Contenu du fichier lemma_file_path : #{File.read(lemma_file_path)}")
  File.foreach(lemma_file_path).with_index do |line, mot_idx_in_lemma|
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
  # Traitement de quelques cas <unknown> connus… (sic)
  if canon == LEMMA_UNKNOWN
    type, canon = case mot
    when 't' then ['PRO:PER', 'te']
    else [type, canon]
    end
  end
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

end #/Texte
