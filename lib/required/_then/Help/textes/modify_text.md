## Modification du texte

### Gabarit des commandes

Toutes les commandes de modification de texte s'expriment par :

    `:<commande> <index ref>[ <texte>]`

Où :

* `<commande>` désigne l'opération à exécuter, suppression, inser-
  tion, ignorance, etc. Pour mémoire, cette opération se définit
  toujours sur 3 lettres et seulement 3 lettres (“ins”, “rep”, etc.).

* `<index ref>` désigne l'index des mots qui devront être pris en
  considération. Pour tout savoir sur leur définition utilisée ici,
  taper la commande d'aide `:h[elp] index` (après être sorti de
  l'aide en tapant `q`).

* `<texte>` désigne le texte qui devra être insérer en remplacement
  ou non. Note : les guillemets ne sont pas utiles, ils seraient mar-
  qués dans le texte.
  NB : pour désigner une espace ou un retour-charriot, il faut utili-
  ser `_space_` (espace) ou `_return_` (nouveau paragraphe).

### Liste des commandes

`:rep <index> <texte>`
`:= <index> <texte>`

    Permet de REMPLACER le texte à <index> par le texte
    <texte>.

`:ins <index> <texte>`
`:+ <index> <texte>`

    Permet d'INSÉRER le texte <texte> à l'index <index>. Ici, <index>
    est forcément un nombre simple.

`:rem <index>`
`:- <index> <texte>`
`:del <index>`
`:sup <index>`

    Permet de SUPPRIMER le texte défini par <index>.

Note : toutes ces opérations sont enregistrées dans la table
`operations` et permettent d'être retrouvées.

`:ign <index>`

    Permet d'IGNORER le mot d'index <index>. Ignorer un mot signifie
    qu'il ne sera pas considéré lors des analyses de proximité.
    Noter que cela ne concerne QUE le mot d'index spécifié et aucun
    des autres mots similaires. Pour supprimer tous les mots simi-
    laires, il faut rentrer le mot dans la liste des mots à retirer.

`:inj <index>`

    Réduction de “injecter”, cette commande permet de “désignorer” un
    mot qui aurait été exclu de l'analyse avec la commande précédente
    ou qui le serait pour une autre raison comme sa brièveté.

`:occ[urences] <index|mot>`

    Permet d'obtenir le nombre d'occurences du mot <mot> ou du mot se
    situant à l'index <index> dans le texte courant. La commande af-
    fiche l'occurence du mot exact ainsi que l'occurence du canon.
