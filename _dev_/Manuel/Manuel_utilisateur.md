# Proximity New<br>Manuel utilisateur



## Lancer le programme avec un texte

Pour le moment :

~~~bash
> proxnew path/to/texte.txt

# OU

> newprox
~~~



## Quitter le programme



Pour quitter le programme :

~~~bash
> :q
~~~



## Modification du texte

Les commandes sont TOUJOURS des mots de 3 lettres :

~~~bash
rem		Pour remove, supprimer
sup		Pour supprimer alias de rem
ins		Pour insérer, doit être suivi de 'before/bef' avec l’index du mot avant lequel insérer
rep		Pour remplacer
mov		Pour déplacer
dep		Pour déplacer, alors de mov
~~~



On désigne toujours l’entité par son :

~~~bash
Son index						Un entier simple					12        Le 12e mot
Un rang							entier-tiret-entier				12-14     Les mots 12 à 14
Un nombre dentité		index*nombre							12*3			12 et les 2 mots suivants
~~~



Quelques exemples :



~~~bash
`rem 12-14`						Supprimer les mots de 12 à 14
`ins bef 14 Le mot` 	Insérer "Le mot" avant le mot 14
`mov 23-26 bef 12`		Déplacer les mots 23-26 avant le mot 12
~~~



## Informations du texte



### Configuration du texte

~~~bash
:set distance_minimale_commune <valeur>

# Pour réinitialiser à la valeur par défaut, ne donner aucune valeur
~~~



Pour obtenir une valeur, utiliser `get` :

~~~bash
:get distance_minimale_commune
# => Écrit la valeur en retour
~~~



## Messages

De nombreux moyens existent d’envoyer des messages (trop ?). On peut les envoyer dans trois fichiers différents (journal.log, debug.log, error.log) et dans trois fenêtres différentes : la fenêtre affichant normalement le texte, la fenêtre de log, la fenêtre de statut ou la fenêtre d’interaction.

Pour les messages courants, on peut utiliser la méthode `log` (qui normalement envoie le message à enregistrer dans le fichier `journal.log`) qui avec `true` en second argument affiche le message en plus dans la fenêtre de log (`CWindow.logWind`).

~~~ruby
log("le message", true)
~~~

