# encoding: UTF-8
=begin
  Module pour l'aide

  L'aide a son propre attente interactive.
=end
class Help
AIDE_USER_STRING = <<-EOT
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
                      234     Si l'index est littéral, on affiche le mot à cet
                              index absolu exact dans le fichier.
                      234*    Si l'index est suivi de "*", c'est l'index relatif
                              par rapport à la fenêtre courante. Il peut être
                              négatif, par exemple "-14*" pour voir le 14e mot
                              avant l'affichage
                      234p    Pour afficher la page exacte qui contient l'index
                              absolu 234. Sinon, avec l'index seul, le premier
                              mot est le mot de l'index désiré.

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


  AIDE AU DÉVELOPPEMENT
  ---------------------
  Pour obtenir l'aide au développement de l'application, il faut ajouter
  'dev' ou 'developper' à la commande d'aide :  ':help dev'
  
EOT
end #/Help
