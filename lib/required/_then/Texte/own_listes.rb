# encoding: UTF-8
=begin
  Gestion des listes propres au projet
=end
class Texte
  
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

end #/Texte
