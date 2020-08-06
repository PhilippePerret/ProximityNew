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
# Pour ajouter une erreur au cours du parsing
# @usage
#   add_parsing_error(ParsingError.new(<message>))
#
def add_parsing_error(error)
  error = ParsingError.new(error) if error.is_a?(String)
  Errorer << error.message
  log("ERREUR PARSING: #{error.message}")
  @parsing_errors << error
end #/ add_parsing_error

class Texte
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

# Méthode générale de parsing, pour n'importe quel document, Scrivener ou
# pas.
def parse
  # Initialisations
  self.init
  Canon.init
  # Parser en fonction du type du document
  if projet_scrivener?
    projscriv = Scrivener::Projet.new(path, self)
    parse_projet_scrivener(projscriv) || return
  else
    parse_simple_texte || return
  end
  return true # en cas de succès du parsing
end #/ parse



# = main =
#
# Méthode principale qui traite le fichier
#
# Traiter le fichier consiste à en faire une entité proximité, c'est-à-dire
# un découpage du texte en paragraphes, lines, mots, locutions, non-mots,
# pour permettre le traitement par l'application.
# Le traitement se fait par stream donc le fichier peut avoir une taille
# conséquente sans problème
def parse_simple_texte

  # Pour savoir le temps que ça prend
  start = Time.now.to_f
  log("*** Parsing du texte #{path}")

  # Préparation du texte
  # --------------------
  # La préparation consiste à effectuer quelques corrections comme les
  # apostrophes courbes.
  # Le texte corrigé est mis dans un fichier portant le même nom que le
  # fichier original avec la marque 'c' est il sera normalement détruit à
  # la fin du processus.
  prepare || begin
    log("# Interruption du parsing au niveau de préparation…".freeze, true)
    return false
  end

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || begin
    log("# Interruption du parsing au niveau de la lemmatisation…".freeze, true)
    return false
  end

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || begin
    log("# Interruption du parsing au niveau du recomptage…".freeze, true)
    return false
  end

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
  return false
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

    log("** Traitement du fichier scrivener #{scrivfile.uuid}", true)

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
    prepare(scrivfile) || begin
      log("# Interruption du parsing au niveau de la préparation de #{scrivfile.name}…".freeze, true)
      return false
    end

    # Pour bien séparer les fichiers, on ajoute deux retours charriot
    # entre chaque fichier
    @items << NonMot.new(RC, type:'paragraphe')
    @items << NonMot.new(RC, type:'paragraphe')

  end #/ fin de boucle sur chaque fichier du projet Scrivener

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || begin
    log("# Interruption du parsing au niveau de la lemmatisation…".freeze, true)
    return false
  end

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || begin
    log("# Interruption du parsing au niveau du comptage…".freeze, true)
    return false
  end

  # On termine en enregistrant la donnée finale. Cette donnée, ce
  # sont tous les mots, les canons, ainsi que les préférences sur
  # le texte.
  save

  delai = Time.now.to_f - start

  fin_parsing("PROJET SCRIVENER #{File.basename(projet.path)}", delai)

  return true

rescue Exception => e
  log("PROBLÈME EN PARSANT le projet scrivener #{projet.path} : #{e.message}#{RC}#{e.backtrace.join(RC)}")
  erreur("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
  return false
end #/ parse_projet_scrivener

def init
  @items = []
  @parsing_errors = []
  self.current_first_item = 0
  erase_parsing_files
end #/ init

def show_parsing_errors
  msg = "Des erreurs sont survenues (#{@parsing_errors.count})"
  @parsing_errors.each do |err|
    msg << "#{RC}#{err.message}"
  end
  msg << "Ces problèmes doivent être réglés pour pouvoir déproximiser ce texte."
  CWindow.textWind.write(msg.freeze)
end #/ show_parsing_errors

def fin_parsing(what, duration)
  unless @parsing_errors.empty?
    show_parsing_errors
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
  if out_of_date? # Le fichier doit être actualisé
    log("= Le fichier doit être actualisé")
    return parse
  else # quand le fichier est à jour
    return load
  end
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
  @refonlymots = File.open(only_mots_path,'a') # a été détruit avant
  # On le fait par paragraphe pour ne pas avoir trop à traiter d'un coup
  File.foreach(file_corrected) do |line|
    next if line.strip.empty?
    new_items = traite_line_of_texte(line.strip)
    next if new_items.empty?
    # if new_items.empty?
    #   log("[Découpe fichier] # Aucun item ajouté avec la line #{line.inspect}".freeze)
    #   next
    # else
    #   log("[Découpe fichier] Items ajoutés à itexte.items : #{new_items.count}".freeze)
    # end
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
  @refonlymots.close
end #/ decoupe_fichier_corriged

# Pour écrire dans le fichier qui ne contient que les mots, séparés par
# des espaces (pour lemmatisation)
def write_in_only_mots(str)
  @refonlymots.write(str)
end #/ write_in_only_mots

# +refmotscontainer+ Référence au fichier contenant tous les mots,
# dans le mode normal et un fichier virtuel pour les insertions et
# remplacement.
def traite_line_of_texte(line)
  new_items = []
  mark_style = nil # pour les projets Scrivener
  # C'est ici qu'on va faire la découpe du texte en :
  #     [AMORCE ]MOT NON-MOT
  # Entendu qu'on part du principe qu'un texte est un enchainement
  # entièrement de mot et de non-mot (les non-mots les plus utilisés
  # étant les espaces et ensuite les ponctuations). L'amorce est aussi
  # un non-mot, elle sert par exemple pour les dialogues ou tout texte
  # ou ligne qui commencerait par une apostrophe ou un chevron.
  line.scan(MOT_NONMOT_REG).to_a.each_with_index do |item, idx|
    # next if item.nil? # pas de premier délimiteur par exemple
    amorce, mot, nonmot = item # amorce : le tiret, par exemple, pour dialogue
    # S'il y a une amorce, on l'ajoute
    new_items << NonMot.new(amorce) unless amorce.nil?
    # On traite le mot, qui peut être plus ou moins complexe
    new_items = traite_mot(mot, nonmot, new_items)
    # log("État de new_items : #{new_items.inspect}")
  end #/scan

  # Maintenant qu'on a tous les text-items de la phrase, on peut
  # ajouter les mots dans le fichier des mots seulement
  new_items.each do |titem|
    next unless titem.is_a?(Mot)
    write_in_only_mots("#{titem.content.downcase}#{titem.is_colled ? EMPTY_STRING : SPACE}".freeze)
  end

  return new_items
end #/ traite_line_of_texte

# Traitement général du mot
# -------------------------
# La méthode a été "isolée" car elle peut être appelée aussi bien
# par la méthode `traite_line_of_texte` que la méthode `traite_mot_special`
# Elle retourne systématiquement un Array, même si le mot est unique (entendu
# que justement cette méthode va chercher à analyser un mot rendu complexe à
# cause des apostrophes et des tirets — et autre chose ?)
# @Return {Array of NonMot/Mot}
#
# +mot+   {String} Le mot à traiter
# +nonmot+  {String} Le non-mot relevé après le mot, mais seulement avec la
#     phrase.
# +new_items+   {Array|Nil}   La liste des mots actuels de la phrase traitée
#     lorsque la méthode est appelée par `traite_line_of_texte`. Sinon Nil
#     lorsque la méthode est appelée par `traite_mot_special`
def traite_mot(mot, nonmot = nil, new_items = nil)
  # Pour mettre les mots qui seront ajoutés pour le mot fourni. Entendu
  # qu'un mot unique — p.e. << qu'est-ce >> — peut générer plusieurs mots
  #  — p.e. "qu'", "est" et "ce" —. Mais seulement si new_items n'est pas
  # fourni à la méthode (noter que new_items concerne seulement les mots
  # d'une phrase, pas du texte complet)
  mot_items = []
  # Pour une marque éventuelle de style, avec un projet Scrivener
  mark_style = nil
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
    # QUESTION Que se passera-t-il ici si new_items n'est pas défini,
    # c'est-à-dire qu'on se trouve dans le cadre d'un mot complexe avec
    # un mot comportant un style dans Scrivener (ce qui peut très bien
    # arriver avec "rosa-bleu" et "bleu" dans un style particulier)
    if new_items.nil?
      mot_items.last.mark_scrivener_end = mot[9...12].gsub(/O/,'').to_i
    else
      new_items.last.mark_scrivener_end = mot[9...12].gsub(/O/,'').to_i
    end
    return (new_items || []) + mot_items # rien à faire par la suite
  end

  if mot.match?(/#{TIRET}/) || mot.match?(/#{APO}/)
    traite_mot_special(mot).each do |titem|
      # log("Mot spécial ajouté : #{titem.inspect}")
      if mark_style
        titem.mark_scrivener_start = mark_style
        mark_style = nil
      end
      mot_items << titem
    end
  else
    titem = Mot.new(mot).tap do |inst|
      if mark_style
        inst.mark_scrivener_start = mark_style
        mark_style = nil
      end
    end
    mot_items << titem
  end
  unless nonmot.nil?
    titem = NonMot.new(nonmot).tap do |inst|
      if mark_style
        inst.mark_scrivener_start = mark_style
        mark_style = nil
      end
    end
    mot_items << titem
  end
  return (new_items || []) + mot_items
end #/ traite_mot

def traite_mot_special(mot)
  mots = []
  if mot.match?(/#{APO}/)
    if is_mot_apostrophe?(mot)
      return [Mot.new(mot)]
    else
      # Ce n'est pas un mot comme aujourd'hui, connu pour avoir une
      # apostrophe. S'il n'y qu'une seule apostrophe, on retourne deux
      # Ça peut être quelque chose comme :
      #   qu'aujourd'hui
      #   qu'est-ce
      #   qu'un
      #   d'avant
      bouts = mot.split(APO)
      bouts_debugged = bouts.inspect
      # On met forcément le premier mot comme ça dans la liste des items
      # Par exemple, c'est "qu'" ou "d'". On indique que ce mot doit être
      # collé au suivant, ce qui est toujours le cas (*).
      # (*) Cette "collure" n'est valable que pour constituer le fichier qui
      # sera lemmatisé car pour le fichier normal reconstitué, toutes les
      # espaces et autres ponctuations sont enregistrées entant que text-item
      firstmot = Mot.new(bouts[0] << APO).tap { |m| m.is_colled = true }
      if bouts.count == 1
        # Ça arrive par exemple avec le "L" dans "L’« autre monde »" à
        # cause des chevrons. Dans ce cas, bouts = ["L"]. On peut donc
        # s'arrêter là en retournant simplement le mot apostrophé.
        return [firstmot]
      elsif bouts.count == 2
        return [firstmot] + traite_mot(bouts[1])
      end
      # S'il y a deux apostrophe (maximum) on regarde si le second
      # mot est un mot connu, comme dans "plus qu'aujourd'hui"
      # Sinon, on renvoie les trois mots
      bouts.shift
      deuxi = bouts.join(APO)
      if is_mot_apostrophe?(deuxi)
        return [firstmot, Mot.new(deuxi)]
      else
        motsuiv = if bouts[0].nil?
          add_parsing_error(ParsingError.new("bouts[0] ne devrait pas pouvoir être nil dans #{mot.inspect} (bouts: #{bouts_debugged}). Ça devrait être le troisième mot.", "#{__FILE__}:#{__LINE__}"))
          Mot.new(APO)
        else
          Mot.new(bouts[0] << APO)
        end
        motsuiv.is_colled = true
        return [firstmot, motsuiv] + traite_mot(bouts[1])
      end
    end
  end

  if mot.match?(/#{TIRET}/)
    if is_mot_tiret?(mot)
      # Un mot tiret connu, comme "peut-être" ou "grand-chose"
      # cf. la liste dans constantes/proximites.rb
      return [Mot.new(mot)]
    else
      # Ce n'est pas un mot comme peut-être, connu pour avoir une
      # apostrophe. S'il n'y qu'un seul tiret, on retourne les deux
      # mots avec un tiret ajouté en non mot
      bouts = mot.split(TIRET)
      if bouts.count == 2
        return [Mot.new(bouts[0]), NonMot.new(TIRET, type:'PUN')] + traite_mot(bouts[1])
      end
      # S'il y a deux tirets (maximum) on regarde si le second
      # mot est un mot-tiret connu, comme dans "arrière-grand-père" (c'est
      # juste un exemple car "arrière-grand-père" est un mot-tiret connu)
      # Sinon, on renvoie les trois mots en mettant entre un tiret
      first = bouts.shift
      deuxi = bouts.join(TIRET)
      if is_mot_tiret?(deuxi)
        return [Mot.new(first), NonMot.new(TIRET, type:'PUN')] + traite_mot(deuxi)
      else
        ary_mots = [
          Mot.new(first),
          NonMot.new(TIRET, type:'PUN')
        ]
        ary_mots += traite_mot(bouts[0])
        ary_mots << NonMot.new(TIRET, type:'PUN')
        ary_mots += traite_mot(bouts[1])
        return ary_mots
      end
    end
  end
end #/ traite_mot_special

# Retourne TRUE si le mot +mot+, qui contient une apostrophe, est un
# mot connu comme "aujourd'hui" ou un mot défini propre au projet.
def is_mot_apostrophe?(mot)
  motd = mot.downcase
  MOTS_APOSTROPHE.key?(motd) || liste_mots_apostrophe.key?(motd)
end #/ has_apostrophe?

def is_mot_tiret?(mot)
  motd = mot.downcase
  MOTS_TIRET.key?(motd) || liste_mots_tiret.key?(motd)
end #/ is_mot_tiret?

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
  log("*** Lemmatisation du fichier", true)
  lemma_file_path = Lemma.parse(only_mots_path)
  # log("Contenu du fichier lemma_file_path : #{File.read(lemma_file_path)}")
  File.foreach(lemma_file_path).with_index do |line, mot_idx_in_lemma|
    next if line.strip.empty?
    traite_lemma_line(line, mot_idx_in_lemma) || return
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
    erreur("### ERREUR FATALE LES MOTS NE CORRESPONDENT PLUS :".freeze)
    imot = Mot.items[idx]
    log("### mot:#{mot.inspect}, dans imot: #{imot.content.inspect}, type:#{type.inspect}, canon: #{canon.inspect}")
    if mot.match?(/[\-\']/)
      liste_prog, liste_perso, chose = mot.match?(/'/) ? ['MOTS_APOSTROPHE', 'avec apostrophe', 'mot_apostrophe'] : ['MOTS_TIRETS', 'avec tirets', 'mot_tiret']
      msg = "### Le mot #{mot.inspect} est à ajouter à la liste des mots spéciaux #{liste_perso}"
      msg << "#{RC}### avec la commande :add #{chose} #{mot}"
      msg << "#{RC}### Si c'est un mot commun, l'ajouter à #{liste_prog} dans lib/required/_first/contants/proximites.rb"
      add_parsing_error(msg)
      log(msg, true)
    end
    log("Je retourne false")
    return false
  else # quand tout est normal
    Canon.add(Mot.items[idx], canon)
  end
  return true
end #/ traite_lemma_line

end #/Texte