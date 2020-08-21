## Les Classes d'éléments

On utilise un nombre limité de classes afin de travailler simplement. Exit les paragraphes, lignes et autres pages.

### Classes principales

Pour le programme de façon générale, on trouve :

* **Runner** qui est la classe générale qui gère l’ensemble de l’application.
* **Texte**. Le texte traité, en tant que tel. **`Runner.itexte`** renvoie l’instance du texte courant.
* **TexteExtrait**. L’extrait de texte en cours d’édition. **`Runner.iextrait`** retourne l’extrait courant.

Pour le texte lui-même, on ne trouve que

* **Mot**. Les mots ou les locutions. Peut-être composé exceptionnellement de `not-mot` comme « aujourd'hui » qui comprend une apostrophe.
* **NonMot**. Tout ce qui n’est pas une lettre qui va composer un mot.

Pour le fonctionnement des proximités, on trouve :

* **Canon**. Pour maintenir les canons en temps réel (plus aucune information, pour le moment, n’est conservée concernant les canons). Contrairement aux autres versions de l’application, on ne passe plus par eux pour connaitre les proximités des mots.
* **Proximite**. Petite classe pour s’occuper d’une proximité. Le principe est qu’elles ne soient pas enregistrées, elles sont toujours calculées et instanciées à la volée, à la demande et la nécessité.

### Autres classes

* **AtStructure**. C’est une classe très intéressante qui permet de gérer les index désignant les mots, et principalement les mots à éditer. Elle permet de désigner les mots par des nombres simples (`12` signifiant le nombre d’index 12 dans l’extrait affiché), par des listes d’index (`12,14,23` désignant les mots 12, 14 et 23) ou un rang d’index pour remplacer ou supprimer plusieurs mots d’un coup par exemple (`12-15` désignant les text-items de 12 à 15).
  Elle contient une méthode très utile, la méthode `:abs` qui retourne l’index absolu des valeurs conservées (entendu que les index conservés dans une instance `AtStructure` sont relatifs à la page affichée). Par exemple, la propriété `@list` d’une instance `AtStructure` contient dans tous les cas la liste des index relatifs concernés. Le résultat de `at.abs(:list)` retournera la liste des index absolus.
  Cette classe est systématiquement utilisée avec les opérations (insertion, remplacement, suppression, déplacement).
