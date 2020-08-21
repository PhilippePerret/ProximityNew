## Traitement des projets Scrivener

Le traitement d’un projet Scrivener pose de nombreux problèmes dont notamment :

* la répartition du texte dans plusieurs fichiers,
* l’enregistrement (pour ma part) en RTF.

La procédure de traitement suit ce parcours :

1. On lit le fichier `.scrivx` du projet pour relever la liste des fichiers du manuscrit.
2. On traite chaque fichier séparément, séquentiellement, en enregistrant avec le mot son identifiant de fichier. Les identifiants sont des nombres qui s’incrémentent régulièrement. De cette manière on sait que le fichier suivant le fichier d’un mot qui est dans le fichier 1 est le fichier 2.
3. Ce traitement est « normal » dans le sens où on découpe le texte en mots et non-mots pour pouvoir le travailler. Une des différences est que le fichier peut comporter des marques spéciales comment `<$Scrv_...>`.
4. On découpe le texte complet pour récupérer les textes de chaque fichier du projet Scrivener.
5. On produit chaque nouveau fichier `content.rtf` tout en conservant l’ancien avec le nom `content-backup<date>.rtf`. Certaines corrections sont faites, par exemple pour la transformation des marques de styles.



### Traitement particulier des balises Scrivener

Les balises Scrivener ressemblent à : `<$Scr_Cs::0>///<!$Scr_Cs::0>`. Peut-être que ça n’est que les balises de style.

Comment les traiter ?

Dans le fichier `.txt` (où les apostrophes courbes sont déjà remplacés par des apostrophes droites), on pourrait imaginer traiter ces balises en les remplaçant par quelque chose qui serait assimilé à un mot comme :

~~~bash
<$Scr_Cs::0>Le où les mots<!$Scr_Cs::0> sont longs

# ->

XSCRIV000Le XSCRIV000où XSCRIV000les XSCRIV000mots sont longs
~~~

Ensuite, dans le traitement des lignes, on repère les mots qui commencent par `XSCRIV`, on relève leur nombre — toujours sur trois chiffres — et on l’enregistre dans l’instance du mot. Le remettre à le reconstitution du texte est un jeu d’enfant.
