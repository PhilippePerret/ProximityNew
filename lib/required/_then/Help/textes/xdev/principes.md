## Principes généraux

Le programme PROXIMIY s’utilise **en ligne de commande** — ou plutôt « dans le Terminal » car c’est une ligne de commande plus élaborée avec Curses — ceci, principalement, pour permettre d’utiliser ruby sans avoir à faire de requêtes Ajax.

#### Mode simple/mode Scrivener

Le programme travaille sous deux modes :

* simple : un texte (un fichier) est donné et on le modifie
* Scrivener : un roman Scrivener est donné et on le modifie

#### Tout console

Tout fonctionne comme dans Vim (normal) à base de commandes clavier. Chaque mot est repéré par un index, il est donc simple de procéder à des remplacements par `rep 13 le nouveau texte` pour « remplacer le mot 13 par “le nouveau texte” » ou `ins 12 ce nouveau contenu` pour « insérer “ce nouveau contenu” avant le mot 12 ».

Un système de **mode de clavier** permet une gestion intelligente. Par exemple, lorsqu’on a tapé « :ins  » (l’espace est volontaire), le clavier passe en mode « chiffres simples » qui permet d’entrer les chiffres avec les touches de Q à M, ce qui est plus pratique. lorsque l’on a « :ins 234 » et que l’on joue une espace, l’espace est écrite et on repasse en passe normal pour taper le texte à insérer.

#### Documentation dans le code

Puisque tout sera chargé d'un coup (ou presque), je n'ai pas peur d'alourdir les fichiers. Donc les méthodes sont très documentées à l'intérieur des modules eux-mêmes. Dans ce fichier manuel du développeur je ne parlerai que des choses générales qui ne peuvent pas se trouver à un endroit précis.

La documentation du projet est produite par [~~Yard~~](https://yardoc.org/) rien pour le moment.

#### Usage intense de la base de données (SQLite)

Pour travailler le texte, on fait un usage intense de la base de données. Tous les mots, au départ, y sont enregistrés. Ensuite, on fonctionne en insertion et en suppression (jamais en modification, à part de l’index et de l’offset) et on laisse les triggers SQL rectifier les choses :

* quand on insert un élément, un trigger modifie les éléments (text-items) se trouvant après l’insertion, en ajoutant 1 à l’index de chaque mot suivant et la longueur de l’insertion à l’offset de chaque mot suivant.
* inversement, quand on supprime un élément, un trigger modifie les éléments (text-items) se trouvant après la suppression, en retirant 1 à leur index et en retirant la longueur de la suppression à leur offset.

L’usage intense des bases de données se fait aussi au niveau de la base propre à l’application, qui contient dans sa base, dans la table `lemmas`, toutes les formes lemmatisées jusqu’à aujourd’hui. Cela afin d’alléger le travail de TreeTagger.
