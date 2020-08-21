## Annexe

### Autres commandes

Trouvez ici la liste d'autres commandes utiles.

#### `:update --force`

Permet de forcer le reparsing du texte. Attention, cette commande va
détruire l'intégralité des modifications opérées jusque-là, pour re-
partir depuis le texte original. C'est donc une commande fortement
destructrice.

#### `:debug <what>`

C'est plutôt une commande développeur qui permet d'afficher l'état de
l'application et de ses éléments. Le résultat de cette commande se
trouvera dans le fichier `logs/debug.log` du dossier de l'applica-
tion. On peut trouver :

* `:debug canon <mot>` : donne la valeur du canon du mot <mot>.
* `:debug canons` : renseigne tous les canons courants.
* `:debug mot/item <index>` : affiche les informations sur le mot
  d'index donné.
* `:debug mots` : affiche dans debug.log tous les text-items du
  texte, tels qu'ils sont utilisés dans l'application.

#### Aide au développement

Pour obtenir l'aide au développement, on utilise la commande :

    `:h[elp][ sujet] -d/--dev`
