# Modules principaux

Cette page essaie de répertorier les modules principaux de l'application et la manière de les atteindre facilement.

* Tout ce qui est commandes (texte commençant par `:` dans l'interface), est défini dans le fichier `Commande.rb` qu'il suffit donc d'appeler par `CMD T - "Comman…"`. Ce module contient un grande `CASE… WHEN… END` qui gère les différentes commandes.

* Tout ce qui concerne la classe `Runner` qui est en fait l'application se trouve dans le module `Runner.rb` et peut s'atteindre par `CMD T - "runn…"`

* Tout ce qui concerne la grande classe `TexteItem` qui gère les mots et les non-mots peut s'atteindre par `CMD T - "texte item"`.

* Tout ce qui concerne le texte analysé est géré par le module `Texte.rb` qui peut s'atteindre par `CMD T - "texte"`. En tapant `CMD ALT MAJ L` pour le localiser, on peut atteindre les sous-modules de cette classe (le sous-module `parsing.rb` par exemple qui concerne le parsing du texte — qu'on peut atteindre directement à l'aide de `CMD T - "pars…"`)

* Les bases de données (de l'application ou du texte) sont gérées par le module `db.rb` qui peut être atteint par `CMD T - "db"`.

* Pour modifier cette aide, `CMD T - "help"` devrait afficher le module `Help.rb`.

* Les **modes claviers** (taper la commande `:h modes_clavier -d` pour savoir ce que c'est) ainsi que les caractères spéciaux se gèrent dans le module `interact.rb` qu'il suffit d'appeler par `CMD T - "inter…"`.
