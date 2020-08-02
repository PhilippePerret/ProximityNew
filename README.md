# Proximity-New

Nouvelle tentative pour gérer le travail des proximités, pour trouver enfin une version qui soit efficiente.

# Principes

* Puisqu'on ne recherchera jamais à contrôler les proximités à plus de 3000 signes, on peut considérer que le travail de calcul de distance entre deux mots n'est pas très consommateur, il peut être fait "en direct". Seul compte la longueur du mot, qui peut être calculée à tout changement.
* Contrairement aux versions précédentes, on ne va plus s'embêter avec les "textes entre les mots" où on les ponctuations étaient comprises dans les mots, ce qui est pour le moins absurbe.

# Questions

* Faut-il exploiter les entités grossissantes : le mot, la locution ("peu à peu", "peut-être"), la proposition (séparée par des virgules et des tirets), la ligne (propositions jusqu'à un point), le paragraphe (ensemble de lignes jusquà un retour charriot). Avec, pour chaque élément :
  * sa position par rapport à l'élément précédent (pas sa position dans l'absolu car il faudrait alors modifier toutes les <<données suivantes>> après chaque modification). Par exemple, on pourra dire que la proposition P2 se trouve à une distance 14 de la proposition P1 et que P3 se trouve à une distance 34 de la proposition P2. Dans ce cas, si P1 change et passe de la longueur 14 à la longueur 26, seule la distance de P2 par rapport à P1 sera à modifier. Note : y a-t-il à retenir la distance si on retient la longueur de chaque élément. Si la longueur de P1 est 14 alors P2 est à 14 de P1.
  * Les entités qu'on peut vraiment garder sont : mot, locution, ligne, paragraphe.
