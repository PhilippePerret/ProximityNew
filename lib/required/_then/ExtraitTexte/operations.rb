# encoding: UTF-8
class ExtraitTexte
# ---------------------------------------------------------------------
#
#   Opérations sur le texte
#
# ---------------------------------------------------------------------

# Remplacer un mot par un ou des autres
# Le remplacement consiste à supprimer l'élément courant et à insérer le
# nouvel élément à la place (ou *les* nouveaux éléments)
def replace(params)
  params.merge!({
    real_at: AtStructure.new(params[:at], from_item),
    operation: 'replace'
  })
  CWindow.log("Remplacement du/des mot/s #{params[:at]||params[:real_at].at} par “#{params[:content]}”")
  if params[:content] == '_space_' || params[:content] == '_return_'
    # Pas besoin de simulation pour ajouter une espace ou un retour chariot
    # Ça se fait directement
    params.merge!(nosim: true)
    params.merge!(is_balise: true)
  end
  unless params[:nosim]
    simulation(params) || return
    params.merge!(nosim:true)
  end
  remove(params.merge(noupdate: true))
  insert(params.merge)
end #/ replace

# Suppression d'un ou plusieurs mots
def remove(params)
  params[:real_at] ||= begin
    AtStructure.new(params[:at], from_item).tap { |at| params.merge!(real_at: at) }
  end
  params.merge!(operation: 'remove') unless params.key?(:operation)
  # Il faut simuler la suppression si nécessaire (note : ça n'arrive pas
  # pour une pure suppression — i.e. sans remplacement)
  unless params[:nosim]
    # simulation(params) || return # Essai aucune simulation
    # Note : si je remets cette simulation, ça va poser problème lorsqu'on
    # fait une simple suppression d'un mot. C'est arrivé en essayant de
    # supprimer le dernier mot du simple_text.txt
  end
  at = params[:real_at]
  # Dans tous les cas il faut retirer les mots de leur canon (si ce sont
  # des mots)
  at.list.each do |idx|
    titem = Runner.itexte.items[idx]
    Canon.remove(titem) if titem.mot?
  end

  # Si c'est une vraie suppression (i.e. pas un remplacement), il faut
  # supprimer aussi l'espace après. S'il n'y a pas d'espace après, il faut
  # supprimer l'espace avant s'il existe.
  # La formulaire est différente en fonction du fait qu'on ait un rang ou
  # un index seul et une liste discontinue d'index.
  # ATTENTION AUSSI : l'espace supplémentaire à supprimer est peut-être
  # dans la liste des index à supprimer.
  if params[:operation] == 'remove'
    if at.list?
      # Pour une liste, on doit faire un traitement particulier : il faut
      # vérifier les text-item après chaque "trou"
      liste_finale = at.list.dup
      at.list.each_with_index do |idx, idx_in_list|
        # Les non-mots doivent être passés
        next if itexte.items[idx].non_mot?
        # On passe ce mot si le mot suivant appartient aussi à la liste
        next if at.list[idx_in_list + 1] == idx + 1
        # On passe ce mot si le mot précédent appartient aussi à la liste
        next if at.list[idx_in_list - 1] == idx - 1
        # On doit tester ce mot qui est "seul" dans la liste, c'est-à-dire
        # que la liste ne contient ni son mot juste après ni son mot
        # juste avant.
        next_index = idx + 1
        next_titem = itexte.items[next_index]
        prev_index = idx - 1
        prev_index = nil if prev_index < 0
        prev_titem = prev_index.nil? ? nil : itexte.items[prev_index]
        if next_titem && next_titem.space?
          # On l'ajoute à la liste des items à supprimer
          liste_finale.insert(idx_in_list + 1, next_index)
        elsif prev_titem && prev_titem.space?
          liste_finale.insert(idx_in_list, prev_index)
        end
      end #/ boucle sur la liste

      # Si la liste finale a changé, il faut corrigé le at
      if liste_finale != at.list
        params[:real_at] = at = AtStructure.new(liste_finale.join(VG), from_item)
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
      if itexte.items[next_index].space?
        params[:real_at] = at = AtStructure.new("#{at.first}-#{next_index}", from_item)
      elsif prev_index && itexte.items[prev_index].space?
        params[:real_at] = at = AtStructure.new("#{prev_index}-#{at.last}", from_item)
      end
    end

  end

  # On mémorise l'opération pour pouvoir la refaire
  if params.key?(:cancellor) # pas quand c'est une annulation
    at.list.each do |idx|
      params[:cancellor] << {operation: :insert, index: idx, content: itexte.items[idx].content}
    end
  end

  # On procède vraiment à la suppression des mots dans le texte
  # lui-même, avec une formule différente en fonction du fait que c'est
  # un rang ou une liste (note : un index unique a été mis dans une liste
  # pour simplifier les opérations)
  if at.range?
    Runner.itexte.items.slice!(at.from, at.nombre)
  else
    at.list.each {|idx| Runner.itexte.items.slice!(idx)}
  end

  unless params[:noupdate]
    update(params[:real_at].at)
    Runner.itexte.save
  end
end #/ remove

# Insert un ou plusieurs mots
def insert(params)
  params[:real_at] ||= AtStructure.new(params[:at], from_item)
  params.merge!(operation: 'insert') unless params.key?(:operation)
  unless params[:nosim]
    simulation(params) || return
  end
  if params[:content] == '_space_' || params[:content] == '_return_'
    params.merge!(is_balise: true)
  end
  msg = "Insertion de “#{params[:content]}” #{params[:real_at].to_s} (avant “#{Runner.itexte.items[params[:real_at].at].content}”)"
  log(msg)
  CWindow.log(msg)

  # :is_balise est true quand on donne '_space_' ou '_return_' comme texte
  # à utiliser pour l'opération.
  unless params[:is_balise]
    begin
      tempfile = Tempfile.new('getmots')
      refonlymots = File.open(tempfile, 'a')
      # Ici, il faut appliquer le nouveau découpage. Noter que l'insertion ne
      # peut pas comporter des retours charriot, c'est déjà un repère.
      # new_mots = Lemma.parse_str(params[:content], format: :instances)
      Mot.init # remet la liste à vide, juste pour le contrôle des lemma
      new_items = itexte.traite_line_of_texte(params[:content], refonlymots)
    ensure
      refonlymots.close
    end
    # Si c'est une pure insertion, il faut ajouter une espace soit avant
    # soit après les nouveaux items. On l'ajoute après si le titem d'après
    # est un mot (.mot?) et on l'ajoute avant si le titem avant est un mot.
    if params[:operation] == 'insert'
      next_titem = itexte.items[params[:real_at].at]
      prev_titem = itexte.items[params[:real_at].first - 1]
      if next_titem && next_titem.mot? && new_items.last.mot?
        # Dans le cas où l'item suivant existe, que c'est un mot, et que
        # le dernier titem à insérer est aussi un mot, il faut ajouter
        # une espace à la fin des nouveaux items.
        new_items << NonMot.new(SPACE, type: 'space')
      elsif prev_titem && prev_titem.mot? && new_items.first.mot?
        # Sinon, dans le cas où l'item précédent existe, que c'est un mot
        # et que le premier item à insérer est aussi un mot, il faut ajouter
        # une espace au début des nouveaux items
        new_items.unshift(NonMot.new(SPACE, type:'space'))
      end
    end
  else
    new_item = case params[:content]
    when '_space_'  then NonMot.new(SPACE, type:'space')
    when '_return_' then NonMot.new(RC, type:'paragraphe')
    end
    new_items = [new_item]
  end
  log("Nouveaux items ajoutés (#{new_items.count}) : ")
  log(new_items.inspect)

  Runner.itexte.items.insert(params[:real_at].at, *new_items)
  # Pour l'annulation (sauf si c'est justement une annulation)
  if params.key?(:cancellor)
    idx = params[:real_at].at
    new_items.each do |titem|
      content = titem.space? ? '_space_' : titem.content
      params[:cancellor] << {operation: :remove, index: idx, content: content}
      # Note : le content, ci-dessus, ne servira que pour la vérification
    end
  end

  # Il faut traiter ces items qui n'ont été qu'instanciés pour le moment
  unless params[:is_balise]
    # Si c'est une balise (_space_ ou _return_) on n'a pas besoin
    # de faire ce travail.
    begin
      Lemma.parse_str(File.read(tempfile)).split(RC).each_with_index do |line, idx|
        log("Lemma line : #{line.inspect} (index : #{idx.inspect})")
        index_mot = idx # + first_index_in_mots
        itexte.traite_lemma_line(line, index_mot)
      end
    ensure
      tempfile.delete
    end
  end #/sauf si c'est une balise

  unless params[:noupdate]
    update(params[:real_at].at)
    Runner.itexte.save
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
  debug("-> simulation avec paramètres : #{params.inspect}")
  # Si on a besoin de connaitre l'opération, elle se trouve dans
  # params[:operation]

  # On ré-initialise la liste des mots, pour pouvoir lemmatiser
  # Rappel : cette liste des mots sera comparée à la liste des mots relevés
  # par TreeTagger dans le fichier des seuls mots. La comparaison permettra
  # d'affecter les canons aux Mots.
  Mot.init
  begin
    # On crée un fichier temporaire pour enregistrer les nouveaux mots.
    # Note : très souvent, il y a un seul mot.
    tempfile = Tempfile.new('getmots')
    refonlymots = File.open(tempfile, 'a')
    # On traite le(s) nouveau(x) mot(s) comme une ligne
    new_items = itexte.traite_line_of_texte(params[:content], refonlymots)
  ensure
    refonlymots.close
  end

  debug("[Simulation] new_items = #{new_items.inspect}")

  # On prend seulement les mots parmi les nouveaux mot/non-mots créés
  new_mots = new_items.select { |titem| titem.mot? }

  debug("[Simulation] les mots gardés : #{new_mots.inspect}")

  begin
    Lemma.parse_str(File.read(tempfile)).split(RC).each_with_index do |line, idx|
      mot, type, canon = line.strip.split(TAB)
      # Traitement de quelques cas <unknown> connus… (sic)
      if canon == LEMMA_UNKNOWN
        type, canon = case mot
        when 't' then ['PRO:PER', 'te']
        else [type, canon]
        end
      end
      new_mot = new_mots[idx]
      new_mot.type    = type
      new_mot.canon   = canon
      new_mot.icanon  = Canon.items_as_hash[canon] # peut être nil
      debug("[Simulation] Réglage de #{new_mot.cio}")
      debug("             Type: #{new_mot.type}")
      debug("             Canon: #{canon} #{new_mot.icanon.inspect}")
    end
  ensure
    tempfile.delete
  end

  # *** ON peut vérifier ***

  confirmations = []

  # Position à laquelle les mots doivent être insérés
  insert_at_index     = params[:real_at].at
  debug("[Simulation] insert_at_index : #{insert_at_index.inspect}")
  inserted_at_offset  = itexte.items[insert_at_index].offset
  debug("[Simulation] inserted_at_offset : #{inserted_at_offset.inspect}")

  # On regarde s'il y a des risques de proximité
  new_mots.each do |new_mot|
    debug("[Simulation] *** Étude du mot #{new_mot.cio}")
    # Si new_mot n'a pas de canon, c'est qu'aucun autre mot de sa
    # famille n'existe dans le texte. Il ne peut pas avoir de proximités. On
    # peut passer directement au suivant.
    new_mot.icanon || next
    # Si c'est un mot qui a un canon ignoré, on le passe
    next if new_mot.icanon.ignored?
    # Distance minimale pour que deux mots ne soient pas en proximité
    min_distance = new_mot.icanon.distance_minimale
    debug("= Distance minimale attendue : #{min_distance.inspect}")
    # Principe : si un offset du canon est à moins de cette distance, c'est
    # que le mot risque d'entrer en proximité
    new_mot.icanon.offsets.each_with_index do |offset, idx|
      distance = (offset - (inserted_at_offset + new_mot.length / 2))
      distance_abs = distance.abs
      debug("= Distance avec le mot #{idx} du canon : #{distance}")
      # Si c'est un mot trop loin vers la droite
      if distance_abs > min_distance
        break if distance > 0
        # Si le mot est trop loin vers la gauche, on passe au suivant
        next if distance < 0
      end
      # Si on passe ici, c'est que le mot est en proximité
      # Pour la sémantique
      is_mot_canon_avant = distance < 0
      # Proximité trouvée !
      debug("= Le mot #{idx} du canon crée une proximité !")
      mot_en_prox = new_mot.icanon.items[idx]
      confirmations << "#{new_mot.content.inspect} avec mot #{is_mot_canon_avant ? '<-' : '->'} #{mot_en_prox.content.inspect} (idx #{mot_en_prox.index - from_item} à #{distance_abs})."
    end
    # Le décalage du mot suivant s'il y en a plusieurs à insérer
    # C'est une approximation
    inserted_at_offset += new_mot.length + 1
  end

  unless confirmations.empty?
    CWindow.log("Risque proximités : #{confirmations.join(VGE)}.#{RC}'o' ou 'y' ou ENTRÉE => confirmer / 'z' ou 'n' => renoncer.")
    while true
      s = CWindow.uiWind.wait_for_char
      case s
      when 'y', 'o', 27
        CWindow.log("Confirmation.")
        return true
      when 'z', 'n' then
        CWindow.log("Annulation.")
        return false
      else
        CWindow.log(s)
      end
    end
  else
    # Aucune proximité
    return true
  end
end #/ simulation

end #/ExtraitTexte
