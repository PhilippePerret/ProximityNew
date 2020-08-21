## Listes spéciales

Les listes spéciales permettent de définir le traitement particulier
de certains mots. À commencer par les mots du texte qu'il faut ne pas
considérer au cours de l'analyse du texte.

Il arrive fréquemment, par exemple, qu'on ne tienne pas compte des
prénoms des personnages de l'histoire.

### Liste des mots à ne pas proximiser

Pour retirer des mots de l'analyse des proximités, c'est-à-dire que
leur proximité ne doit pas être analysée, on utilise la commande :

    `:add mot_sans_prox <mot>`

Inversement, pour retirer un mot propre au texte exclus de l'analyse,
on joue la commande :

    `:remove mot_sans_prox <mot>`

### Liste des mots apostrophés

S'il s'agit d'un mot oublié dans les mots communs avec apostrophes,
il convient de l'ajouter à la liste dans le programme qui consigne
ces valeurs.

Si, en revanche, il s'agit d'un mot propre au texte, on l'ajoute à la
liste des mots à apostrophe à l'aide de la commande :

    `:add mot_apostrophe <le'mot>`

Inversement, on retire le mot à l'aide de la commande :

    `:remove mot_apostrophe <le'mot>`


### Liste des mots avec tiret

S'il s'agit d'un mot oublié dans les mots communs avec tirets, il
convient de l'ajouter à la liste dans le programme qui consigne ces
valeurs.

Si, en revanche, il s'agit d'un mot propre au texte, on l'ajoute à la
liste des mots à tiret à l'aide de la commande :

    `:add mot_tiret <le-mot>`

Inversement, on peut retirer le mot avec la commande :

    `:remove mot_tiret <le-mot>`
