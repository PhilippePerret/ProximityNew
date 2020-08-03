# Proximity-New<br>Manuel développeur



## Principes généraux

Le programme s’utilise **en ligne de commande** — ou plutôt « dans le Terminal » car c’est une ligne de commande plus élaborée — ceci, principalement, pour permettre d’utiliser ruby sans avoir à faire de requêtes Ajax. La version non javascript doit permettre aussi, plus tard, une intégration plus facile dans Scrivener ou « avec » Scrivener.

#### Mode simple/mode Scrivener

Le programme doit pouvoir travailler sous deux modes :

* simple : un texte (un fichier) est donné et on le modifie
* scrivener : un roman Scrivener est donné et on le modifie

##### Tout console

Tout fonctionne comme dans Vim (normal) à base de commandes clavier. Chaque mot est repéré par un index, il est donc simple de procéder à des remplacements par `rep 13 le nouveau texte` pour « remplacer le mot 13 par “le nouveau texte” » ou `ins 12 ce nouveau contenu` pour « insérer “ce nouveau contenu” avant le mot 12 ».



## Classes d'éléments

On utilise un nombre minimum de classes afin de travailler simplement. Exit les paragraphes, lignes et autres pages.

* **mot**. Les mots ou les locutions. Peut-être composé exceptionnellement de `not-mot` comme « aujourd'hui » qui comprend une apostrophe.
* **not-mot**. Tout ce qui n’est pas une lettre qui va composer un mot.
* **canon**. Pour maintenir les canons. Les canons, principalement, permettent de savoir rapidement si un mot est en proximité avec un autre.
* **Texte**. Le texte traité, en tant que tel. **`Runner.itexte`** renvoie le texte courant.
* **TexteExtrait**. L’extrait de texte en cours d’édition. **`Runner.iextrait`** retourne l’extrait courant.



## Sauvegarde des données

Elles sont sauvées de deux façons principales :

* dans le fichier modifié, même si on ne travaille jamais sur le fichier original,
* dans un fichier Marshal qui contient toutes les instances.



## Fonctionnement de la première analyse du texte

On commence par fournir le texte à NewProximity à l’aide de :

* en ligne de commande par `newprox /path/to/the/file.txt`,
* dans le programme lancé par `open /path/to/the/file.txt`.