# encoding: UTF-8
class ExtraitTexte
# ---------------------------------------------------------------------
#     Méthodes pour le débuggage
#
# Régler les trois valeurs ci-dessous en fonction des envies et
# des besoins.
# ---------------------------------------------------------------------
def debug_ignore?
  false
end #/ debug_ignore?
def debug_replace?
  false
end #/ debug_replace?
def debug_remove?
  false
end #/ debug_remove?
def debug_insert?
  false
end #/ debug_insert?

# ---------------------------------------------------------------------
#
#   Opérations sur le texte
#
# ---------------------------------------------------------------------

def ignore(params)
  log("-> ignore#{params.inspect}") if debug_ignore?
  params.merge!({
    real_at: AtStructure.new(params[:at]),
    operation: 'ignore'
  })
  params[:real_at].list.each do |tid|
    titem = extrait_titems[tid]
    titem.is_ignored = true
    # Pour le moment, on l'enregistre tout de suite, ça ne devrait pas
    # trop consommer
    itexte.db.update_prop_ignored(titem, true)
    # titem.modified = true # pour savoir qu'il faudra l'enregistrer
    log("Titem #{titem.cio} est marqué à ignorer.", true)
  end
  # Actualiser l'affichage, mais sans marquer l'extrait modifié
  # (sinon, c'est la méthode `update` qu'il faut appeler)
  update(save = false)
end #/ ignore

def unignore(params)
  params.merge!({
    real_at: AtStructure.new(params[:at]),
    operation: 'unignore'
  })
  params[:real_at].list do |titem|
    titem.is_ignored = false
    itexte.db.update_prop_ignored(titem, false)
  end
  # pour actualiser l'affichage mais sans marquer que l'extrait est à
  # enregistrer
  update(saveable = false)
end #/ un_ignore

# Remplacer un mot par un ou des autres
# Le remplacement consiste à supprimer l'élément courant et à insérer le
# nouvel élément à la place (ou *les* nouveaux éléments)
#
def replace(params)
  params.merge!({
    real_at: AtStructure.new(params[:at]),
    operation: 'replace'
  })

  # Pour conserver le text-item de référence
  params.merge!(titem_ref: extrait_titems[params[:real_at].at])

  if debug_replace?
    log("-> replace(params:#{params.inspect})")
  end

  CWindow.log("Remplacement du/des mot/s #{params[:real_at].at} par “#{params[:content]}”")
  if ['_space_', '_return_'].include?(params[:content])
    # Pas besoin de simulation pour ajouter une espace ou un retour chariot
    # Ça se fait directement
    log("   C'est une balise, simulation inutile. is_balise est aussi mis à true")
    params.merge!(is_balise: true)
  end

  # Si c'est une balise _space_ ou _return_, aucune simulation n'est nécessaire
  # Mais on doit la faire dans le cas contraire.
  unless params[:is_balise]
    new_titems = simulation(params.merge(debug: debug_replace?)) || return
    params[:new_titems] = new_titems
  end

  msg = "Remplacement de #{params[:real_at].content.inspect} (index #{params[:real_at].at}) par #{params[:content].inspect}."
  log(msg, true)

  # On enregistre cette opération sur le texte
  # Noter qu'il faut le faire avant les opérations elles-mêmes pour que les
  # index et indices ne soient pas encore recalculés suite à l'opération.
  itexte.operator.add_text_operation(params)

  remove(params)
  insert(params)

end #/ replace







# Suppression d'un ou plusieurs mots
def remove(params)
  params[:real_at] ||= AtStructure.new(params[:at]).tap { |at| params.merge!(real_at: at) }

  # Le text-item de référence
  unless params.key?(:titem_ref)
    params.merge!(titem_ref: extrait_titems[params[:real_at].at])
  end

  # Pour connaitre l'opération, pour faire la distinction, plus tard, entre
  # une pure suppression et un remplacement. Elle permet aussi d'enregistrer
  # l'opération dans l'historique operations.txt
  unless params.key?(:operation)
    params.merge!(operation: 'remove')
  end

  # Un débug (régler les valeurs en haut de ce module)
  if debug_replace? || debug_remove?
    log("-> remove(params=#{params.inspect})")
  end

  if params[:operation] == 'remove'
    msg = "Suppression de #{extrait_titems[params[:real_at].at].content.inspect} (index #{params[:real_at].at})."
    log(msg, true)
  end


  # Si c'est une vraie suppression (i.e. pas un remplacement), il faut
  # supprimer aussi l'espace après. S'il n'y a pas d'espace après, il faut
  # supprimer l'espace avant s'il existe.
  # La formule est différente en fonction du fait qu'on ait un rang ou
  # un index seul et une liste discontinue d'index.
  # ATTENTION AUSSI : l'espace supplémentaire à supprimer est peut-être
  # dans la liste des index à supprimer et dans ce cas il faut étudier
  # le mot suivant et le text-item non-mot suivant.
  #
  # Le but de cette partie est donc de produire la liste exacte des text-items
  # qui doivent être finalement supprimé.
  # Elle n'est valable que pour une suppression pure car pour un replacement,
  # il faut garder tous les éléments autour du mot ou des mots remplacés.
  at = params[:real_at]
  if params[:operation] == 'remove'
    if at.list?
      # Pour une liste, on doit faire un traitement particulier : il faut
      # vérifier les text-item après chaque "trou"
      liste_finale = at.list.dup
      at.list.each_with_index do |idx, idx_in_list|
        # Les non-mots doivent être passés
        next if extrait_titems[idx].non_mot?
        # On passe ce mot si le mot suivant appartient aussi à la liste
        next if at.list[idx_in_list + 1] == idx + 1
        # On passe ce mot si le mot précédent appartient aussi à la liste
        next if at.list[idx_in_list - 1] == idx - 1
        # On doit tester ce mot qui est "seul" dans la liste, c'est-à-dire
        # que la liste ne contient ni son mot juste après ni son mot
        # juste avant.
        next_index = idx + 1
        next_titem = extrait_titems[next_index]
        prev_index = idx - 1
        prev_index = nil if prev_index < 0
        prev_titem = prev_index.nil? ? nil : extrait_titems[prev_index]
        if next_titem && next_titem.space?
          # On l'ajoute à la liste des items à supprimer
          liste_finale.insert(idx_in_list + 1, next_index)
        elsif prev_titem && prev_titem.space?
          liste_finale.insert(idx_in_list, prev_index)
        end
      end #/ boucle sur la liste

      # Si la liste finale a changé, il faut corrigé le at
      if liste_finale != at.list
        params[:real_at] = at = AtStructure.new(liste_finale.join(VG))
      end

    else
      # Pour un rang et un index seul, le traitement est plus simple, il
      # suffit de voir l'index après le dernier.
      # Noter qu'on ne supprime pas les espaces ici, on modifie le rang
      # ou on transforme l'index en range, ceci afin de ne pas provoquer
      # de doubles suppressions
      next_index = at.last + 1
      prev_index = at.first - 1
      prev_index = nil if prev_index < 0
      if extrait_titems[next_index].space?
        params[:real_at] = at = AtStructure.new("#{at.first}-#{next_index}")
      elsif prev_index && extrait_titems[prev_index].space?
        params[:real_at] = at = AtStructure.new("#{prev_index}-#{at.last}")
      end
    end

  end

  # On mémorise l'opération pour pouvoir l'annuler
  if params.key?(:cancellor) # pas quand c'est une annulation
    at.list.each do |idx|
      params[:cancellor] << {operation: :insert, index: idx, content: itexte.items[idx].content}
    end
  end

  # SUPPRESSION
  # ------------
  # On procède vraiment à la suppression des mots dans le texte
  # lui-même, avec une formule différente en fonction du fait que c'est
  # un rang ou une liste (note : un index unique a été mis dans une liste
  # pour simplifier les opérations)
  if at.range?
    extrait_titems.slice!(at.from, at.nombre)
  else
    at.list.each {|idx| extrait_titems.slice!(idx)}
  end

  # Si c'est vraiment une opération de destruction, on l'enregistre
  # en tant qu'opération et on actualise l'affichage en indiquant que
  # l'extrait a changé
  if params[:operation] == 'remove'
    itexte.operator.add_text_operation(params)
    update(saveable = true)
  end

end #/ remove










# Insert un ou plusieurs mots
def insert(params)
  params[:real_at] ||= AtStructure.new(params[:at])

  if ['_space_', '_return_'].include?(params[:content])
    params.merge!(is_balise: true)
  end

  params.merge!(operation: 'insert') unless params.key?(:operation)
  # On ajoute si nécessaire le text-item de référence, qui permettra,
  # notamment, de renseigner les messages, de récupérer le file_id si c'est
  # un projet Scrivener, pour l'affecter aux nouveaux text-items et
  # d'enregistrer les messages d'opération.
  params.merge!(titem_ref: extrait_titems[params[:real_at].at]) unless params.key?(:titem_ref)
  # Sauf si c'est une balise (*), on crée la simulation pour voir si on va vraiment faire
  # cete opération.
  # (*) Car on ne peut pas occasionner de proximités quand c'est une balise.
  unless params[:is_balise]
    new_titems = simulation(params.merge(debug: debug_insert?)) || return
  end

  if params[:operation] == 'insert'
    msg = "Insertion de “#{params[:content]}” à l’index #{params[:real_at].at} (avant “#{extrait_titems[params[:real_at].at].content}”)"
    log(msg, true)
  end

  # :is_balise est true quand on donne '_space_' ou '_return_' comme texte
  unless params[:is_balise]
    # Si c'est une pure insertion, il faut ajouter une espace soit avant
    # soit après les nouveaux items. On l'ajoute après si le titem d'après
    # est un mot (.mot?) et on l'ajoute avant si le titem avant est un mot.
    if params[:operation] == 'insert'
      next_titem = extrait_titems[params[:real_at].at]
      prev_titem = extrait_titems[params[:real_at].first - 1]
      if next_titem && next_titem.mot? && new_titems.last.mot?
        # Dans le cas où l'item suivant existe, que c'est un mot, et que
        # le dernier titem à insérer est aussi un mot, il faut ajouter
        # une espace à la fin des nouveaux items.
        new_titems << NonMot.new(SPACE, type: 'space')
      elsif prev_titem && prev_titem.mot? && new_titems.first.mot?
        # Sinon, dans le cas où l'item précédent existe, que c'est un mot
        # et que le premier item à insérer est aussi un mot, il faut ajouter
        # une espace au début des nouveaux items
        new_titems.unshift(NonMot.new(SPACE, type:'space'))
      end
    end
  else
    new_item = case params[:content]
    when '_space_'  then NonMot.new(SPACE, type:'space')
    when '_return_' then NonMot.new(RC, type:'paragraphe')
    end
    new_titems = [new_item]
  end
  # log("Nouveaux items ajoutés (#{new_titems.count}) : ")
  # log(new_titems.inspect)

  # Si c'est un projet Scrivener, il faut ajouter le file_id de l'item
  # de référence aux nouveaux items
  if itexte.projet_scrivener?
    new_titems.each {|titem| titem.file_id = params[:titem_ref].file_id}
  end

  extrait_titems.insert(params[:real_at].at, *new_titems)
  # Pour l'annulation (sauf si c'est justement une annulation)
  if params.key?(:cancellor)
    idx = params[:real_at].at
    new_titems.each do |titem|
      content = titem.space? ? '_space_' : titem.content
      params[:cancellor] << {operation: :remove, index:idx, content:content}
      # Note : le content, ci-dessus, ne servira que pour la vérification
    end
  end

  # Si c'est vraiment une opération d'insertion, on l'enregistre
  # en tant qu'opération.
  # Noter qu'il faut le faire avant l'update suivant, sinon tous les
  # index et indices seront recalculés et donc faux.
  if params[:operation] == 'insert'
    itexte.operator.add_text_operation(params)
  end

  unless params[:noupdate]
    update(saveable = true)
  end
end #/ insert










# Crée une simulation de l'opération pour s'assurer qu'elle est possible
# sans générer de proximités. Le cas échéant on demande à l'utilisateur
# de confirmer l'opération.
# +params+
#   :real_at        Objet At qui permet de savoir où insérer
#   :content        Le contenu à insérer
#   :operation      Opération ('insert','replace' ou 'insert')
def simulation(params)
  debug("-> simulation. Quelques paramètres : content:#{params[:content].inspect}, operation:#{params[:operation]}, at:#{params[:at]}") if params[:debug]
  # Si on a besoin de connaitre l'opération, elle se trouve dans
  # params[:operation]

  # On ré-initialise la liste des mots, pour pouvoir synchroniser la liste
  # des mots du fichier lemmatisé et les mots relevés ici. Cette comparaison
  # permet d'affecter les canons (s'ils ne sont pas trouvés dans la table
  # lemmas des canons du texte).
  Mot.init
  begin
    # Fichier temporaire pour enregistrer les mots.
    tempfile = Tempfile.new('getmots')
    refonlymots = File.open(tempfile, 'a')
    new_titems = itexte.traite_line_of_texte(params[:content], refonlymots)
  ensure
    refonlymots.close
  end

  debug("[Simulation] new_titems = #{new_titems.inspect}") if params[:debug]

  # D'abord, il faut voir si les mots fournis ne sont pas déjà connus de la
  # base de données, ce qui irait plus vite que TreeTagger
  # Liste pour mettre les mots qu'il faudra passer à TreeTagger parce qu'ils
  # ne sont pas encore connus de la table `lemma` du texte.
  # Cette liste fonctionne comme new_mots et new_non_mots, avec des nils pour
  # les non valeurs et la bonne place (le bon index) pour les mots qui devront
  # être TreeTaggerisé.
  new_mots_for_treetagger = []
  # On boucle sur chaque mot pour voir celui qui est connu
  new_titems.each_with_index do |new_titem, idx|
    next if not new_titem.mot?
    hcanon = Runner.db.get_canon(new_titem.content)
    if hcanon.nil?
      new_mots_for_treetagger << new_titem
    else
      debug("Canon trouvé pour #{new_titem.inspect} : #{hcanon.inspect}") if params[:debug]
      new_titem.type  = hcanon['Type']
      new_titem.canon = hcanon['Canon']
    end
  end

  debug("Mots dans canon dans la db (#{new_mots_for_treetagger.count}) : #{new_mots_for_treetagger.inspect}") if params[:debug]

  # +new_mots_for_treetagger+ contient la liste des instances des nouveaux mots
  # pour lesquels on n'a pas trouvé de canon dans la table `lemmas`. On doit
  # rechercher leur canon à l'aide de TreeTagger
  unless new_mots_for_treetagger.empty?
    mots_as_string = new_mots_for_treetagger.collect{|new_mot|new_mot.content}.join(SPACE)
    Lemma.parse_str(mots_as_string).split(RC).each_with_index do |line, idx|
      mot, type, canon = line.strip.split(TAB)
      new_mot = new_mots_for_treetagger[idx]
      new_mot.type    = type
      new_mot.canon   = canon
      if params[:debug]
        debug("[Simulation] Canonisation de #{new_mot.to_s}")
        debug("             Type: #{new_mot.type}")
        debug("             Canon: #{canon}")
      end
    end
  end # / sauf si on a trouvé tous les mots

  # On peut mettre tous les nouveaux titems dans les paramètres, ce qui
  # permettra de ne pas avoir à les recalculer dans la méthode.
  params.merge!(new_titems: new_titems)
  debug("Nouveaux text-items mis dans params: #{new_titems.inspect}") if params[:debug]

  # *** On peut vérifier enfin les proximités ***

  confirmations = []

  # On regarde s'il y a des risques de proximité
  new_titems.each do |new_mot|
    # Si c'est un mot non proximizable, on le passe. Les non-mots seront
    # donc automatiquement passés. C'est également le cas si le mot est
    # trop court, si son canon est ignoré.
    next if not new_mot.proximizable?

    debug("[Simulation] *** Étude des proximités du mot #{new_mot.cio}") if params[:debug]

    # Principe pour rechercher les proximités avant et après :
    # On utilise les méthodes #prox_avant et #prox_apres de l'instance qui
    # n'a besoin maintenant que de connaitre l'index dans l'extrait de
    # l'item. Il n'est pas défini pour le moment mais on peut le définir
    # provisoirement le temps de cette recherche.
    # Noter que pour le moment, comme ça, se pose le problème du remplacement,
    # car les mots à supprimer pour le remplacement se trouveront toujours là.
    # Ça se pose clairement lorsqu'on remplace un temps par un autre. Par exemple,
    # dans la phrase :
    #     "Il trouvera peut-être"
    # TODO
    # Si on veut remplacer "trouvera" par "a trouvé", le programme trouvera
    # la proximité avec "trouvera" et signalera une erreur.
    # Pour remédier à ce problème, il faudrait pouvoir faire la recherche sur
    # une liste où les suppressions ont déjà été faites.

    # On règle les valeurs du nouveau mot pour pouvoir calculer ses proximités
    # avant et après. L'index dans l'extrait permet de savoir de où il faut
    # partir pour regarder et l'offset (pris dans le text-item de référence)
    # permet de calculer la distance entre les mots.
    new_mot.reset
    new_mot.index_in_extrait = params[:real_at].at
    new_mot.offset = params[:titem_ref].offset

    # On cherche avant
    # ----------------
    debug("[Simulation] Prox avant du mot : #{new_mot.prox_avant.inspect}") if params[:debug]
    if new_mot.prox_avant
      titem_avant = new_mot.prox_avant.mot_avant
      confirmations << "#{titem_avant.content.inspect} (#{titem_avant.index_in_extrait}) <- "
    end

    # On cherche après
    # ----------------
    debug("[Simulation] Prox après du mot : #{new_mot.prox_apres.inspect}") if params[:debug]
    if new_mot.prox_apres
      titem_apres = new_mot.prox_apres.mot_apres
      confirmations << " -> #{titem_apres.content.inspect} (#{titem_apres.index_in_extrait})"
    end
  end #/Fin de boucle sur tous les nouveaux items

  if not confirmations.empty?
    CWindow.log("RISQUE PROXIMITÉS :", pos:[0,0], color: CWindow::RED_COLOR)
    CWindow.log(" #{confirmations.join(SPACE)}.#{RC}", pos: :keep, color: CWindow::BLUE_COLOR)
    CWindow.log("o/y/Entrée => confirmer         z/n => renoncer.", pos:[2,2])
    case CWindow.wait_for_user(keys: ['y','o',27,'z','n'])
    when 'y', 'o', 27
      log("Confirmation.", true)
      return new_titems
    when 'z', 'n'
      log("Annulation.", true)
      return false
    end
  else
    # Aucune proximité
    debug("= Aucune proximité trouvée =") if params[:debug]
    return new_titems
  end
end #/ simulation

end #/ExtraitTexte
