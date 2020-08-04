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
  params.merge!(real_at: AtStructure.new(params[:at], from_item))
  remove(params.merge(noupdate: true))
  insert(params)
end #/ replace

# Suppression d'un ou plusieurs mots
def remove(params)
  params[:real_at] ||= begin
    AtStructure.new(params[:at], from_item).tap { |at| params.merge!(real_at: at) }
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
  msg = "Insertion de “#{params[:content]}” #{params[:real_at].to_s} (avant “#{Runner.itexte.items[params[:real_at].at].content}”)"
  log(msg)
  CWindow.log(msg)
  # Ici, il faut appliquer le nouveau découpage. Noter que l'insertion ne
  # peut pas comporter des retours charriot, c'est déjà un repère.
  # new_mots = Lemma.parse_str(params[:content], format: :instances)
  tempfile = Tempfile.new('getmots')
  Mot.init # remet la liste à vide, juste pour le contrôle des lemma
  begin
    refvirtualfile = File.open(tempfile, 'a')
    # NB Il faut toujours ajouter une espace après params[:content] pour
    # être sûr que l'expression régulière de traite_line_of_texte, qui cherche
    # un mot + un non-mot, trouve son bonheur. Si params[:content] termine
    # déjà par un non-mot, ça n'est pas grave, puisque l'espace ne sera pas
    # pris en compte.
    content_pour_reg = "#{params[:content]} "
    new_items = itexte.traite_line_of_texte(content_pour_reg, refvirtualfile)
    Mot.add(new_items)
  ensure
    refvirtualfile.close
  end

  log("Nouveaux items ajoutés (#{new_items.count}) : ")
  log(new_items.inspect)
  Runner.itexte.items.insert(params[:real_at].at, *new_items)
  # Il faut traiter ces items qui n'ont été qu'instanciés pour le moment

  begin
    Lemma.parse_str(File.read(tempfile)).split(RC).each_with_index do |line, idx|
      log("Lemma line : #{line.inspect} (index : #{idx.inspect})")
      index_mot = idx # + first_index_in_mots
      itexte.traite_lemma_line(line, index_mot)
    end
  ensure
    tempfile.delete
  end

  unless params[:noupdate]
    update(params[:real_at].at)
    Runner.itexte.save
  end
end #/ insert

end #/ExtraitTexte
