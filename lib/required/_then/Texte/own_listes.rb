# encoding: UTF-8
=begin
  Gestion des listes propres au projet
=end
class Texte

  def liste_mots_sans_prox
    @liste_mots_sans_prox ||= begin
      config[:liste_mots_sans_prox] || {}
    end
  end #/ liste_mots_sans_prox

  def liste_mots_tiret
    @liste_mots_tiret ||= begin
      config[:liste_mots_tiret] || {}
    end
  end #/ liste_mots_tiret

  def liste_mots_apostrophe
    @liste_mots_apostrophe ||= begin
      config[:liste_mots_apostrophe] || {}
    end
  end #/ liste_mots_apostrophe

  def add_mot_sans_prox(mot)
    if liste_mots_sans_prox.key?(mot.downcase)
      erreur("Le mot #{mot.inspect} est déjà dans la liste des mots sans proximité. Pour le retirer, utiliser ':remove mot_sans_prox #{mot}'.")
    elsif mot.gsub(WORD_DELIMITERS,'') != mot
      erreur("Le mot #{mot.inspect} n'est pas un “pur” mot. Je ne peux pas l'ajouter à la liste (il ne sera pas reconnu comme mot).")
    else
      motd = mot.downcase
      liste_mots_sans_prox.merge!(motd => true)
      config.save(liste_mots_sans_prox: liste_mots_sans_prox)
      log("Mot #{motd.inspect} ajouté à la liste des mots sans proximités propre au texte.".freeze, true)
    end
  end #/ add_mot_sans_prox

  def remove_mot_sans_prox(mot)
    if liste_mots_sans_prox.key?(mot.downcase)
      liste_mots_sans_prox.delete(mot.downcase)
      config.save(liste_mots_sans_prox: liste_mots_sans_prox)
    else
      erreur("Le mot #{mot.inspect} n'appartient pas à la liste des mots sans proximité…")
    end
  end #/ remove_mot_sans_prox

  def add_mot_tiret(mot)
    if liste_mots_tiret.key?(mot.downcase)
      erreur("Le mot #{mot.inspect} est déjà dans la liste des mots tirets du texte.")
    else
      motd = mot.downcase
      liste_mots_tiret.merge!(motd => true)
      config.save(liste_mots_tiret: liste_mots_tiret)
      log("Mot #{motd.inspect} ajouté à la liste des mots avec tiret propres au texte.".freeze, true)
    end
  end #/ add_mot_tiret

  def remove_mot_tiret(mot)
    if liste_mots_tiret.key?(mot.downcase)
      liste_mots_tiret.delete(mot.downcase)
      config.save(liste_mots_tiret: liste_mots_tiret)
    else
      erreur("Le mot #{mot.inspect} n'appartient pas à la liste des mots avec tiret propres au projet…")
    end
  end #/ remove_mot_tiret

  def add_mot_apostrophe(mot)
    if liste_mots_apostrophe.key?(mot.downcase)
      erreur("Le mot #{mot.inspect} est déjà dans la liste des mots apostrophes du texte.")
    else
      motd = mot.downcase
      liste_mots_apostrophe.merge!(motd => true)
      config.save(liste_mots_apostrophe: liste_mots_apostrophe)
      log("Mot #{motd.inspect} ajouté à la liste des mots avec apostrophe propres au texte.".freeze, true)
    end
  end #/ add_mot_apostrophe

  def remove_mot_apostrophe(mot)
    if liste_mots_apostrophe.key?(mot.downcase)
      liste_mots_apostrophe.delete(mot.downcase)
      config.save(liste_mots_apostrophe: liste_mots_apostrophe)
    else
      erreur("Le mot #{mot.inspect} n'appartient pas à la liste des mots avec apostrophe propres au projet…")
    end
  end #/ remove_mot_apostrophe


end #/Texte
