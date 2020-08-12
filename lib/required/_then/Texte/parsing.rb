# encoding: UTF-8
=begin
  Méthode de parsing du texte
=end

# Tous les signes, dans le texte, qui vont être considérés comme ne
# constituant pas un mot. Donc les apostrophes et les tirets sont exclus.
WORD_DELIMITERS = '  ?!,;:\.…—–=+$¥€«»\[\]\(\)<>“”' # pas de trait d'union, pas d'apostrophe

# Utile pour la nouvelle formule
REG_NO_WORD_DELIMITERS = /([#{WORD_DELIMITERS}]+)/ # les parenthèses vont capturer, dans split.
REG_WORD_DELIMITERS =  /[^#{WORD_DELIMITERS}]+/
REG_APO_OR_TIRET = /[#{APO}#{TIRET}]/.freeze

REG_APO_OR_TIRET_CAP = /([#{APO}#{TIRET}])/.freeze

# Table qui va contenir en clé les mots trouvés dans le texte et en valeur
# leur canon. Cette table permet de n'enregistrer qu'un seul mot dans la
# table sqlite `lemmas` qui permet de retrouver très vite un canon de mot.
PARSED_LEMMAS = {}

# Pour les erreurs à enregistrer
ParsingError = Struct.new(:message, :where)

class Texte
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

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

# = main =
# Méthode générale de parsing, pour n'importe quel document, Scrivener ou
# pas.
def parse

  # Initialisations
  # Il faut tout remettre à zéro, notamment les mots et les Canons.
  self.init
  Canon.init
  Mot.init
  PARSED_LEMMAS.clear
  db.reset

  # Parser en fonction du type du document (simple texte ou projet
  # Scrivener)
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
    log.close
    return false
  end

  # On lemmatise la liste de tous les mots, on ajoutant chaque
  # mot à son canon.
  lemmatize || begin
    log("# Interruption du parsing au niveau de la lemmatisation…".freeze, true)
    log.close
    return false
  end

  save_titems_in_db || begin
    log("# Interruption du parsing au niveau du sauvetage des mots dans la DB…".freeze, true)
    log.close
    return false
  end

  # On doit recalculer tout le texte. C'est-à-dire définir les
  # offsets de tous les éléments
  recompte || begin
    log("# Interruption du parsing au niveau du recomptage…".freeze, true)
    log.close
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

# On crée toutes les instances mots dans la base de données ici
def save_titems_in_db
  self.items.each do |titem|
    titem.insert_in_db
  end
  return true
end #/ save_titems_in_db
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
      log.close
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

  save_titems_in_db || begin
    log("# Interruption du parsing au niveau du sauvetage des mots dans la DB…".freeze, true)
    log.close
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
  log.close
  erreur("Une erreur est survenue : #{e.message} (quitter et consulter le journal)")
  return false
end #/ parse_projet_scrivener

def init
  @items = []
  @parsing_errors = []
  @refonlymots = nil
  self.current_first_item = 0
  erase_parsing_files
  CWindow.textWind.clear
end #/ init

def show_parsing_errors
  msg = "Des erreurs sont survenues (#{@parsing_errors.count})"
  @parsing_errors.each do |err|
    msg << "#{RC}#{err.message}"
  end
  msg << "#{RC*2}Ces problèmes doivent être réglés pour pouvoir déproximiser ce texte."
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
# Deux utilisations différentes de cette méthode :
#   * pour un texte quelconque (1 fois au début)
#   * pour un projet Scrivener (pour chaque fichier, 2 fois)
#
# La méthode s'appelle à deux endroits différents quand on traite un
# projet Scrivener : au commencement du parsing, pour détruire les fichiers
# généraux et avant le traitement de chaque fichier pour détruire les
# full_text_path et les refaire.
# == Params:
#   +scrivfile+   {ScrivFile}   Instance du fichier de Scrivener
#
def erase_parsing_files(scrivfile = nil)
  proprio = scrivfile || self
  file_list = []
  if scrivfile.nil?
    file_list << only_mots_path
    file_list << data_path
    file_list << full_text_path
    file_list << corrected_text_path
    file_list << rebuild_file_path
    file_list << operations_file_path
  else
    file_list << proprio.full_text_path
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
    file_to_correct = sfile.full_text_path
    file_corrected  = sfile.corrected_text_path
    # Il faut préparer le fichier Scrivener
    sfile.prepare
  else # simple copie du fichier texte, si pas projet Scrivener
    FileUtils.copy(path, full_text_path)
    file_to_correct = full_text_path
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
  @refonlymots = nil
end #/ decoupe_fichier_corriged

# Pour écrire dans le fichier qui ne contient que les mots, séparés par
# des espaces (pour lemmatisation)
def write_in_only_mots(str)
  @refonlymots.write(str)
end #/ write_in_only_mots

# +refmotscontainer+ Référence au fichier contenant tous les mots,
# dans le mode normal et un fichier virtuel pour les insertions et
# remplacement.
# @Params
#   @params   {Hash}
#       :debug    Si true, on affiche les messages de débug
def traite_line_of_texte(line, reffileonlymots = nil, params = nil)
  params ||= {}
  @refonlymots = reffileonlymots unless reffileonlymots.nil?
  new_items = []
  line = line.strip

  # *** Nouvelle façon de découper le texte ***
  # On utilise la faculté de String#split à conserver les délimiteurs s'ils
  # sont placés entre parenthèses capturantes.
  mots = line.split(REG_NO_WORD_DELIMITERS)
  # Si la liste commence par un string vide, c'est que la ligne commence
  # par un non-mot. Par exemple pour un dialogue, on trouve :
  # [ "", "— ", "Bonjour", " ", "tout", " ", "le", " ", "monde", " !" ]
  line_starts_with_non_mot = mots.first == EMPTY_STRING

  log("Les mots découpés : #{mots.inspect}") if params[:debug]

  # On retourne les listes pour pouvoir pop(er) au lieu de shift(er) pour
  # des raisons de performances. Mais pour des listes aussi courtes, est-ce
  # qu'on ne perd pas plus de temps à reverser qu'à shift(er) au lieu de
  # pop(er) ?…
  # Rappel : #pop va plus vide que #shift car la seconde est obligée de
  # ré-indexer toute la liste à chaque fois.
  mots.reverse!

  # Si la ligne ne commence pas par un mot, il faut prendre ce non-mot et
  # le mettre au début de la liste des nouveaux text-items.
  if line_starts_with_non_mot
    mots.pop # pour retirer le string vide découlant de la découpe
    new_items << NonMot.new(mots.pop)
  end

  # On traite ensuite le mot et son non-mot suivant.
  begin
    mot     = mots.pop
    nonmot  = mots.pop # peut être nil
    imot = TextWordScanned.new(mot, nonmot)
    new_items += imot.scan

    imot = nil
  end until mots.empty?

  # Maintenant qu'on a tous les text-items de la phrase, on peut
  # ajouter les mots dans le fichier des mots seulement. On en profite
  # pour définir la propriété :lemma qui est peut-être déjà définie (voir
  # l'explication dans la classe Mot)
  new_items.each do |titem|
    if titem.content.nil?
      raise "TITEM NIL #{titem.inspect} items:#{new_items.inspect} (line: #{line})"
    end
    next unless titem.mot?
    titem.lemma ||= titem.content.downcase
    write_in_only_mots("#{titem.lemma}#{titem.is_colled ? EMPTY_STRING : SPACE}".freeze)
  end

  return new_items
end #/ traite_line_of_texte

# On prend le fichier texte (contenant tout le texte initial ou le texte
# du fichier d'un projet Scrivener) et on le corrige pour qu'il puisse être
# traité. Cette opération @produit le fichier +file_corrected_path+
def prepare_fichier_corriged(file_to_correct, file_corrected_path)
  log("*** Préparation du fichier corrigé")
  File.delete(file_corrected_path) if File.exists?(file_corrected_path)
  reffile = File.open(file_corrected_path,'a')
  begin
    has_apostrophes_courbes = nil
    File.foreach(file_to_correct) do |line|
      next if line == RC # on passe les retours charriot seuls
      if !has_apostrophes_courbes
        has_apostrophes_courbes = !!line.match?(/’/)
        # log("has_apostrophes_courbes = #{has_apostrophes_courbes.inspect}")
      end
      line = line.gsub(/’/, APO)
      reffile.puts line
    end
    # Il faut enregistrer dans les informations du texte que les
    # apostrophes courbes ont été remplacées, ou pas
    config.save(apostrophes_courbes: has_apostrophes_courbes)
    # log("Configuration enregistrée (apostrophes_courbes: #{has_apostrophes_courbes.inspect})")
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
  Lemma.parse(self)
  # log("Contenu du fichier lemma_data_path : #{File.read(lemma_data_path)}")
  File.foreach(lemma_data_path).with_index do |line, mot_idx_in_lemma|
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
    log("+++ canon inconnu pour : #{line}")
    type, canon = case mot
    when 't' then ['PRO:PER', 'te']
    else [type, canon]
    end
  end
  titem = Mot.items[idx]
  titem.type = type
  if mot != (titem.lemma || titem.content.downcase)
    expose_erreur_desynchro(mot:mot, titem:titem, idx:idx, canon:canon)
  else
    # Quand le mot lemmatisé correspond au mot enregistré dans Mot.items (cas
    # normal)
    # on peut définir le canon du mot. (sera supprimé dans les version ultérieures)
    Canon.add(Mot.items[idx], canon)
    # On regarde s'il faut enregistrer cette forme lemmatisée
    # On le sait de deux manières : en consultant la table des mots qui ont
    # déjà été lemmatisés au cours de ce parsing (pour aller plus vite) et en
    # regardant si ce canon est connu dans la table `lemmas` de l'application.
    # Si c'est le cas, on renseigne la table `lemmas` de la base de données de
    # proximité (Runner.db) pour que cette forme soit accessible à tout
    unless PARSED_LEMMAS.key?(mot) || Runner.db.canon_exists_for?(mot)
      PARSED_LEMMAS.merge!(mot => canon)
      Runner.db.add_mot_and_canon(mot, type, canon)
    end
  end
  return true
end #/ traite_lemma_line

# Quand une erreur de desynchro (*) se pose, on donne le maximum de
# renseignements pour pouvoir corriger le problème.
#
# (*) Une erreur de désynchro signifie que le fichier pour la lemmatisation
#     ne correspond plus à la liste des mots enregistrée dans Mot.items qui
#     a été composée au moment du parsing du texte.
#
def expose_erreur_desynchro(params)
  # erreur(err)

  # Données envoyées par +params+
  idx = params[:idx]
  mot = params[:mot]
  titem = params[:titem]
  canon = params[:canon]

  # Informations sur le mot lemma et le text-item
  log("### Informations sur le mot et le text-item :")
  log("### Index : #{idx}")
  log("### Text-item")
  log("###    content  : #{titem.content.inspect}")
  log("###    type     : #{titem.type.inspect}")
  log("###    lemma    : #{titem.lemma.inspect}")
  log("###    file_id : #{titem.file_id} / Path: #{ScrivFile.get_path_by_file_id(titem.file_id)}") if titem.file_id
  log("### Mot lemmatisé (fichier des seuls mots)")
  log("###    mot    : #{mot.inspect}")
  log("###    canon  : #{canon.inspect}")

  if mot.match?(REG_APO_OR_TIRET)
    # Si le mot contient une apostrophe ou un tiret, on suggère de l'ajouter à
    # la liste des mot spéciaux de chaque type.
    liste_prog, liste_perso, chose = mot.match?(/'/) ? ['MOTS_APOSTROPHE', 'avec apostrophe', 'mot_apostrophe'] : ['MOTS_TIRET', 'avec tirets', 'mot_tiret']
    msg = "### Mots ne correspondant pas."
    msg << "### Le mot #{mot.inspect} (index #{idx}) peut être à ajouter à la liste des mots spéciaux #{liste_perso}#{RC}"
    msg << "### avec la commande :add #{chose} #{mot}#{RC}"
    msg << "### Si c'est un mot commun, l'ajouter à #{liste_prog} dans lib/required/_first/contants/proximites.rb"
  else
    # Le mot ne contient ni tiret ni apostropthe, c'est un mot normal,
    # on affiche l'extrait du texte pour voir ce que ça peut être.
    # Extrait à partir des mots
    extrait = ("…" + ((idx - 20)..(idx + 20)).collect do |i|
      i > -1 || next
      Mot.items[i]&.content
    end.compact.join(SPACE) + '…').freeze
    # Extrait à partir des lignes
    extrait_lemma = []
    File.foreach(lemma_data_path).with_index do |line, sidx|
      next if sidx < idx - 20
      break if sidx > idx + 20
      extrait_lemma << line.split(TAB).first
    end
    extrait_lemma = extrait_lemma.join(SPACE)

    # Extrait autour du mot problématique
    extraitautour = {}
    File.foreach(lemma_data_path).with_index do |line, sidx|
      # next if sidx < idx - 20
      break if sidx > idx + 10
      extraitautour.merge!( sidx => {lemma:line.split(TAB).first, mot:Mot.items[sidx]&.content} )
    end

    extraitautour = extraitautour.collect{|sidx,hd|"idx:#{sidx} - lemma:#{hd[:lemma]} - mot:#{hd[:mot]}"}.join(RC)


    msg = "Problème avec le mot d'index #{idx} #{titem.content.inspect} (dans Mot.items) différent de #{mot.inspect} (dans le fichier des mots seulement) dans l'extrait :#{RC}#{extrait.inspect}."
    msg << "#{RC}Extrait dans le fichier des mots seuls :#{RC}#{extrait_lemma}"
    if mot == Mot.items[idx+1].content.downcase
      msg << "#{RC}MAIS ça correspond à l'imot suivant d'index #{idx+1}." # on pourrait réparer
    end

    msg << "#{RC}Voir dans le fichier journal le détail"
    log(extraitautour)
  end
  msg << RC*2
  add_parsing_error(msg)
  log(msg, true)
  err = "### ERREUR FATALE LES MOTS NE CORRESPONDENT PLUS (index : idx).".freeze
  raise(err)
end #/ expose_erreur_desynchro

end #/Texte
