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
  CWindow.log("Remplacement du/des mot/s #{params[:at]} par “#{params[:content]}”")
  params.merge!({
    real_at: AtStructure.new(params[:at], from_item),
    operation: 'replace'
  })
  if params[:content] == '_space_' || params[:content] == '_return_'
    # Pas besoin de simulation pour ajouter une espace ou un retour chariot
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
  params.merge!(operation: 'remove')
  unless params[:nosim]
    simulation(params) || return
  end
  at = params[:real_at]
  # Dans tous les cas il faut retirer les mots de leur canon (si ce sont
  # des mots)
  at.list.each do |idx|
    titem = Runner.itexte.items[idx]
    Canon.remove(titem) if titem.mot?
  end
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

  unless params[:is_balise]
    begin
      tempfile = Tempfile.new('getmots')
      refonlymots = File.open(tempfile, 'a')
      # Ici, il faut appliquer le nouveau découpage. Noter que l'insertion ne
      # peut pas comporter des retours charriot, c'est déjà un repère.
      # new_mots = Lemma.parse_str(params[:content], format: :instances)
      Mot.init # remet la liste à vide, juste pour le contrôle des lemma
      # NB Il faut toujours ajouter une espace après params[:content] pour
      # être sûr que l'expression régulière de traite_line_of_texte, qui cherche
      # un mot + un non-mot, trouve son bonheur. Si params[:content] termine
      # déjà par un non-mot, ça n'est pas grave, puisque l'espace ne sera pas
      # pris en compte.
      content_pour_reg = "#{params[:content]} "
      new_items = itexte.traite_line_of_texte(content_pour_reg, refonlymots)
      # Quand c'est une pure insertion, il faut ajouter une espace après
      # le mot inséré. Mais si c'est un remplacement, cette espace existe
      # déjà.
      new_items.pop if params[:operation] == 'replace'
    ensure
      refonlymots.close
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
  # Si on a besoin de connaitre l'opération, elle se trouve dans
  # params[:operation]
  Mot.init # remet la liste à vide, juste pour le contrôle des lemma
  content_pour_reg = "#{params[:content]}#{SPACE}"
  begin
    tempfile = Tempfile.new('getmots')
    refonlymots = File.open(tempfile, 'a')
    new_items = itexte.traite_line_of_texte(content_pour_reg, refonlymots)
    # Cf. l'explication dans l'opération réelle elle-même
    new_items.pop if params[:operation] == 'replace'
  ensure
    refonlymots.close
  end

  # On prend seulement les mots
  new_mots = new_items.select{ |titem| titem.mot? }

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
      new_mot.type = type
      new_mot.canon = canon
      new_mot.icanon = Canon.items_as_hash[canon] # peut être nil
    end
  ensure
    tempfile.delete
  end

  # *** ON peut vérifier ***

  confirmations = []

  # Position à laquelle les mots doivent être insérés
  inserted_at = params[:real_at].at

  # On regarde s'il y a des risques de proximité
  new_mots.each do |new_mot|
    # Si new_mot n'a pas de canon, c'est qu'aucun autre mot de sa
    # famille n'existe dans le texte. Il ne peut pas avoir de proximités. On
    # peut passer directement au suivant.
    new_mot.icanon || next
    # Distance minimale pour que deux mots ne soient pas en proximité
    min_distance = new_mot.icanon.distance_minimale
    # Principe : si un offset du canon est à moins de cette distance, c'est
    # que le mot risque d'entrer en proximité
    new_mot.icanon.offsets.each_with_index do |offset, idx|
      distance = (offset - (inserted_at + new_mot.length / 2)).abs
      if distance < min_distance
        # Proximité trouvée !
        mot_proche = new_mot.icanon.items[idx]
        confirmations << "#{new_mot.content}”⬅︎ ~#{distance} ➡︎“#{mot_proche.content}”"
      end
    end
    inserted_at += new_mot.length + 1 # approximation
  end

  unless confirmations.empty?
    CWindow.log("Cette opération va occasionner de nouvelles proximités : #{confirmations.join(VGE)}.#{RC}Taper 'o' ou 'y' ou ENTRÉE pour confirmer ou 'z' ou 'n' pour renoncer.")
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
