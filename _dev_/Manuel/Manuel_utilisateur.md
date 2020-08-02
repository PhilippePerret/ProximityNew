# Proximity New<br>Manuel utilisateur



## Lancer le programme avec un texte

Pour le moment :

~~~bash
> proxnew path/to/texte.txt
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

