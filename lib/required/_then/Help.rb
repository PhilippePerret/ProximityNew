# encoding: UTF-8
=begin
  Module pour l'aide

  L'aide a son propre attente interactive.
=end
class Help
AIDE_STRING = <<-EOT
=== AIDE DU PROGRAMME PROXIMITÉS ===

'q'[ENTER] pour quitter et revenir au texte. Les flèches ⇅ pour monter
et descendre dans l'aide.

Pour ouvrir un fichier (fichier texte ou projet scrivener), utiliser la
commande :

    :open /path/to/the/file.txt

Pour forcer le recalcul complet du texte (donc en perdant toutes les
modifications qui ont été faites jusque-là), utiliser :

    :update --confirmed

Pour RECONSTRUIRE LE TEXTE COMPLET à partir des modifications
     -----------------------------
opérées.

    :rebuild

    Note : si c'est un projet Scrivener, tous les fichiers sont
    reconstruits et remplacés, une copie de chaque fichier et gardée dans
    le dossier prox.

RECONSTRUCTION "MANUELLE" DU TEXTE
----------------------------------
  Si un problème est survenu et qu'on doit reconstituer tout le texte
  "à la main", notamment pour un fichier Scrivener, il suffit de se servir
  du fichier 'operations.txt' se trouvant dans le dossier proximité du
  texte ou du projet, qui contient toutes les opérations successives de
  modification du texte (et seulement les opérations de modification, pour
  la clarté).


MODIFCATION DU TEXTE
====================

  Toutes les commandes de modification de texte ressemblent à :

      :<cmd> <index> <nouveau texte>

  <cmd> s'exprime toujours sur trois lettres, même si son équivalent
  existe en longueur normale :
    :ins      Insérer un ou des mots
    :rep      Remplacer un ou des mots par un ou des mots
    :rem
    :del      Effacer un ou des mots
    :ign      Ignorer le ou les mots d'index donnés
    :inj      Désignorer le ou les mots d'index donnés

    Non Encore Implémenté
    :mov      Déplacer le ou les mots. Exceptionnellement,
              l'argument suivant définit l'index d'arrivée.

  <index> est l'index du mot dans la fenêtre affichée. Il peut être :

    * un unique index     12        Le mot indexé 12 à l'écran
    * un rang             12-14     Les mots de 12 à 14 compris
    * une liste           12,14,23  Les mots 12, 14 et 23

  <nouveau texte> est le nouveau texte donc les mots.

  On peut ajouter des CARACTÈRES SPÉCIAUX à l'aide de :

    _space_         Une espace
    _return_        Un retour chariot

  Par exemple
  -----------
      :ins 12 le nouveau mot      Insert "le nouveau mot" à l'index 12
      :mov 12-14 6                Déplacer les mots 12,13 et 14 avant le
                                  mot 6
      :rem 13,34,100              Supprimer les mots 12, 34 et 100
      :rep 6-8 rien               Remplacer les mots 6 à 8 par "rien"

      :ins 32 _space_             Insérer une espace à l'index 32.


 AJOUTS DE MOTS À DES LISTES
 ---------------------------

 Chaque projet peut avoir ses propres listes, listes de mots apostrophés,
 liste de mots avec tirets, liste de mots dont il ne faut pas checker la
 proximités. On ajoute des mots à ces listes à l'aide de la commande :add
 avec en deuxième argument la liste à modifier et à la suite le mot en
 question.

 Noter que pour toutes les valeurs ci-dessous, c'est le canon qu'il faut
 indiquer, pas le mot lui-même. Surtout pour mot_sans_prox

    :add mot_sans_prox <mot>      Ajoute "<mot>" à la liste des mots dont il ne
                                  faut pas étudier les proximités.
    :remove mot_sans_prox <m>     Pour le supprimer.

    :add mot_tiret <le-mot>       Ajoute "<le-mot>" à la liste des mots avec
                                  tirets.
    :remove mot_tiret <m>         Pour le supprimer.

    :add mot_apostrophe <le:mot>  Ajoute "<le:mot>" à la liste des mots avec
                                  apostrophes. Noter que si ce mot est un mot
                                  commun, il faut le mettre plutôt dans la liste
                                  des constantes proximités.
    :remove mot_apostrophe <m>    Pour le supprimer.

 AUTRES COMMANDES UTILES
 -----------------------

    :show <index>             Pour afficher le texte à partir de cet
                              index de mot.

    :copy texte <new_name>    Faire une copie du projet actuel sous un autre
                              nom.
    :copy projet <new_name>   Alias de la précédente.

    :next page                Pour passer à la page suivante
    (flèche droite)
    :prev page                Pour passer à la page précédente
    (flèche gauche)

    :set <what> <value>       Permet de définir une valeur
    :get <what>               Permet de connaitre la valeur

        <what> peut être :
          distance_minimale_commune         valeur : un nombre

    :debug <what>[ <value>]   Permet d'obtenir des valeurs du
                              programme dans le journal.log
        <what> peut être :
          canon         valeur : le mot canonique
          canons        Tous les canons.
          mot/item      valeur : index du mot dont il faut voir les
                        infos
          mots          Tous les mots (dans debug.log)

    :canon <mot>        Pour obtenir le canon enregistré dans lemmas
                        du mot <mot>. Si le mot existe dans le texte courant
                        le canon sera déjà connu. Cette table permet de faire
                        gagner du temps dans les recherches. Elle appartient à
                        Proximity et s'enrichit à chaque parsing de fichier.
EOT

class << self
  attr_accessor :first_line, :last_line
  def show(options = nil)
    options ||= {}
    options.merge!(first_line: 0) unless options.key?(:first_line)
    options.merge!(last_line: CWindow.hauteur_texte) unless options.key?(:last_line)
    self.first_line = options[:first_line]
    self.last_line  = options[:last_line]
    CWindow.log("Affichage de l'aide (ligne #{first_line} à #{last_line}).")
    CWindow.textWind.clear
    CWindow.textWind.write(aide_lines[first_line..last_line].join(RC), CWindow::WHITE_ON_BLACK)
    interact_with_user
  end #/ show

  def aide_lines
    @aide_lines ||= AIDE_STRING.split(RC)
  end #/ aide_lines
  def nombre_lignes_aide
    @nombre_lignes_aide ||= aide_lines.count
  end #/ nombre_lignes_aide

  def interact_with_user
    wind  = CWindow.uiWind
    curse = wind.curse # raccourci
    start_search = false
    while true
      s = curse.getch
      case s
      when 'q'
        on_quit
        break
      when '/'
        start_search = true
        search = ""
      when 258 # flèche bas => descendre
        if last_line + 1 < nombre_lignes_aide
          show(first_line: first_line + 1, last_line: last_line + 1)
        end
      when 259 # flèche haut => remonter
        if first_line > 0
          show(first_line: first_line - 1, last_line: last_line - 1)
        end
      when 27 # Escape button
        start_search = false
        search = ""
        wind.clear
        wind.write(EMPTY_STRING)
      when 127 # effacement arrière
        if start_search
          search = search[0...-1]
          wind.clear
          wind.write("/#{search}")
        end
      else
        if start_search && s.is_a?(String)
          search << s
        end
        wind.write(s.to_s)
      end
    end
  end #/ interact_with_user

  def on_quit
    Runner.iextrait&.output
  end #/ on_quit

end # /<< self

end #/Help
