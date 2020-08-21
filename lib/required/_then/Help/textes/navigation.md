## Navigation dans le texte

Une fois parsé et analysé, le texte s'affiche par pages calculées en
fonction de la taille courante de l'interface, donc du Terminal sur
Mac.

Les commandes suivantes permettent de passer de page en page :

`:next page` ou la flèche vers la droite permettent de passer à la
page suivante.

`:prev page` ou la flèche vers la gauche permettent de revenir à la
page précédente.

### Rejoindre un point précis du texte

On peut rejoindre un mot précis du texte à l'aide de la commande :

    `:show <index>`

Elle permet d'afficher une portion particulière du texte, sans tenir
compte des pages définies. Ici, l'index peut être définit de trois
manières différentes :

* **Simple nombre**. Si c'est un simple nombre, par exemple “12”, il
  s'agit de l'index absolu du text-item dans le texte. Cette valeur
  peut donc être très grande avec un long texte. Par exemple :
  `:show 35786`.
* **Nombre suivi d'une étoile**. Par exemple “123*”. Dans ce cas il
  s'agit de l'index du nombre dans la page actuelle. Le mot deviendra
  alors le premier mot de la portion affichée, ce qui permettra par
  exemple de voir les mots qui le suivent.

* **Nombre suivi de la lettre “p”**. Par exemple “123p”. Dans ce cas,
  on affiche la page qui contient le text-item d'index absolu 123. Le
  mot peut alors se retrouver n'importe où dans la page, il n'est pas
  mis en exergue pour le moment.
