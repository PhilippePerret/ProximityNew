## Ouverture d'un texte

Il existe deux moyens d'ouvrir un texte avec proximité.

Lorsque l'application n'est pas encore lancé, si un raccourci
`newprox` ou `prox` a été défini (dans le bash profile par exemple),
il suffit de mettre en premier argument le path complet du fichier
contenant le texte :

~~~
# Dans le Terminal

> prox /full/path/to/texte.txt
~~~

Si l'on se trouve déjà dans l'application, on peut jouer la commande
`:open` suivie du chemin d'accès complet au fichier :

~~~
# Dans Proximity

:open /full/path/to/texte.txt
~~~
