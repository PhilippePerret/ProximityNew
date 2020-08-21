## Annexe

### Les Modes de clavier

Pour faciliter encore plus l'entrée des informations, on utilise des *mode de clavier* en fonction des contextes. Une illustration valant mieux qu'une longue explication, prenons le cas où l'on doit supprimer plusieurs mots à l'aide de la commande `rem` (pour “remove”, détruire). Dès que nous avons tapé `:rem ` au clavier (noter l'espace), l'application passe en mode clavier pour les index et nous pouvons alors utiliser les touches “q” à “m” pour taper les chiffres de 1 à 9 et 0. Dès que nous retapons une espace, nous revenons dans le mode normal, pour écrire un mot par exemple ou pour taper un retour charriot.

On peut désactiver ce mode clavier en jouant la commande :

    `:set mode_clavier off` ou `:set mode_clavier 0`
