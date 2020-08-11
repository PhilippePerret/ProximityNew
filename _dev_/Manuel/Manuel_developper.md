# Proximity-New<br>Manuel développeur



## Principes généraux

Le programme s’utilise **en ligne de commande** — ou plutôt « dans le Terminal » car c’est une ligne de commande plus élaborée avec Curses — ceci, principalement, pour permettre d’utiliser ruby sans avoir à faire de requêtes Ajax. La version non javascript doit permettre aussi, plus tard, une intégration plus facile dans Scrivener ou « avec » Scrivener (c’est fait).

#### Mode simple/mode Scrivener

Le programme doit pouvoir travailler sous deux modes :

* simple : un texte (un fichier) est donné et on le modifie
* Scrivener : un roman Scrivener est donné et on le modifie

#### Tout console

Tout fonctionne comme dans Vim (normal) à base de commandes clavier. Chaque mot est repéré par un index, il est donc simple de procéder à des remplacements par `rep 13 le nouveau texte` pour « remplacer le mot 13 par “le nouveau texte” » ou `ins 12 ce nouveau contenu` pour « insérer “ce nouveau contenu” avant le mot 12 ».

Un système de **mode de clavier** permet une gestion intelligente. Par exemple, lorsqu’on a tapé « :ins  » (l’espace est volontaire), le clavier passe en mode « chiffres simples » qui permet d’entrer les chiffres avec les touches de Q à M, ce qui est plus pratique. lorsque l’on a « :ins 234 » et que l’on joue une espace, l’espace est écrite et on repasse en passe normal pour taper le texte à insérer.

#### Documentation dans le code

Puisque tout sera chargé d'un coup (ou presque), je n'ai pas peur d'alourdir les fichiers. Donc les méthodes sont très documentées à l'intérieur des modules eux-mêmes. Dans ce fichier manuel du développeur je ne parlerai que des choses générales qui ne peuvent pas se trouver à un endroit précis.

La documentation du projet est produite par [Yard](https://yardoc.org/).


## Classes d'éléments

On utilise un nombre limité de classes afin de travailler simplement. Exit les paragraphes, lignes et autres pages.

Pour le programme de façon générale, on trouve

* **Runner** qui est la classe générale qui gère l’ensemble de l’application.
* **Texte**. Le texte traité, en tant que tel. **`Runner.itexte`** renvoie l’instance du texte courant.
* **TexteExtrait**. L’extrait de texte en cours d’édition. **`Runner.iextrait`** retourne l’extrait courant.

Pour le texte lui-même, on ne trouve que

* **mot**. Les mots ou les locutions. Peut-être composé exceptionnellement de `not-mot` comme « aujourd'hui » qui comprend une apostrophe.
* **not-mot**. Tout ce qui n’est pas une lettre qui va composer un mot.

Pour le fonctionnement des proximités, on trouve :

* **canon**. Pour maintenir les canons. Les canons, principalement, permettent de savoir rapidement si un mot est en proximité avec un autre. Les informations dans les `Canon`s, contrairement aux `Proximites`, sont assez complètes.
* **Proximite**. Petite classe pour s’occuper d’une proximité. Le principe est qu’elles ne soient pas enregistrées, elles sont toujours calculées et instanciées à la volée, à la demande et la nécessité.



## Nouveau fonctionnement complet (db)

Le nouveau fonctionnement complet inauguré le 11 août est le suivant :

* on utilise la base (table `text_items` pour enregistrer tous les mots,
* on utilise la base (table `lemmas`) pour enregistrer seulement mot unique et canon,
* on utilise une table générale (table `infos`) pour les données générales, par exemple l’identifiant ou l’index du premier mot du panneau courant.
* on utilise une table provisoire qui contient toutes les informations du panneau courant, à commencer par tous les mots.

### Parsing complet du texte

Au cours du parsing complet du texte, les mots sont enregistrés dans la base `db.sqlite` du dossier prox du texte. Dans `Runner.itexte.items` on ne met plus que les identifiants obtenus des insertions. On renseigne également la table `lemmas` qui contient « un mot = un canon » qui permettra d’obtenir plus tard un grand nombre de canons sans passer par TreeTagger.

Pour ne pas répéter les appels à la table `lemmas` pour savoir si un mot est déjà enregistré, on tient à jour, au cours du parsing, une table `PARSED_LEMMAS` qui listera les mots déjà traités dans leur forme exacte. Cette table contiendra par exemple :

~~~ruby
PARSED_LEMMAS = {
  # ...
  "seraient" => "être",
  "sera" => "être",
  # ...
 }
~~~



### Affichage et modification d’une page

On part du principe qu’on ne peut que modifier les mots d’une page affichée (la modification d’un mot non affiché doit donc être interdit). Donc quand on demande l’affichage d’une page (à partir d’un index de mot) voilà ce qui se passe :

1. Si `offset_first_mot` est l’offset absolu du premier mot à voir, `offset_last_mot` est l’offset absolu du dernier mot à voir et que `distance_minimale_commune` est la distance qui doit séparer deux mots pour qu’ils ne soient pas en proximité, il faut charger les mots dont l’offset est supérieur ou égal à `offset_first_titem - distance_minimale_commune` et l’offset inférieur ou égal à `offset_last_titem + distance_minimale_commune`. 
2. Ces mots sont chargés (comme instances `TextItem`) dans une table qu’on peut appeler `TABLE_TEXT_ITEMS` dont la propriété `items` contient tous les mots chargés.
3. Quand on modifie des mots du panneau courant, on les modifie seulement dans cette table `TABLE_TEXT_ITEMS`.
4. Le fait de ne travailler qu’avec les mots courants permet d’accélérer toutes les modifications et surtout de simplifier les requêtes.
5. On peut même imaginer que cette table soit une table SQL qu’on crée et casse à chaque fois (pour bénéficier par exemple des recherches de proximités comme on le voit plus bas).
6. Dès qu’on change l’index du premier mot affiché, on actualise les données :
   1. les données de `TABLE_TEXT_ITEMS` sont injectés dans la table des `text_items`
   2. la table est détruite
   3. tous les items suivants sont recalculés pour tenir compte des modifications (est-ce que ça n’est pas trop coûteux au niveau des requêtes SQL car il faudrait alors une requête par mot — c’est le seul élément épineux du programme, qu’il faudrait benchmarquer après une première injection des données.)

### Obtenir le canon d’un mot

Au cours du travail (pas au cours du premier parsing), quand on veut obtenir le canon d’un mot, on utilise en premier recours la base. Si le mot a déjà été traité, on obtient tout de suite son canon. S’il n’a pas été traité, on utilise TreeTagger pour l’obtenir.

### Recherche des proximités

Si on utilise la base de données pour mettre le panneau courant, on peut utiliser une requête pour trouver rapidement les mots en proximité, de tel sorte qu’il n’est même plus nécessaire de travailler avec la classe `Canon`. Par exemple, c’est cette requête qui permettra d’obtenir le mot recherché :

~~~ruby
stm = db.prepare <<-SQL.freeze
SELECT id 
	( offset - ? ) AS distance
	FROM current_page 
	WHERE offset > ? AND offset < ?
	ORDER BY distance ASC
	LIMIT 1
SQL

stm = db.bind_param 3, 1210, 1010, 1410
res = stm.execute
row = res.next 
# => [ID du text-items] ou [] si aucune proximité
~~~







---



## Sauvegarde des données

Elles sont sauvées de deux façons principales :

* dans le fichier modifié, même si on ne travaille jamais sur le fichier original,
* dans un fichier Marshal qui contient toutes les instances.



## Fonctionnement de la première analyse du texte

On commence par fournir le texte à NewProximity à l’aide de :

* en ligne de commande par `newprox /path/to/the/file.txt`,
* dans le programme lancé grâce à la commande `open /path/to/the/file.txt`.

Ce texte est découpé en mots et non-mots.



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



## Tests

### Fonctionnement

Dans l’idée, on donne un texte, on effectue une opération, on récupère le texte qui devrait être écrit dans la fenêtre et on le vérifie. Donc principalement :

* simulation d’une commande jouée,
* récupération du texte à afficher (et de tous les messages)





## Réflexions



### Sur les annulations

Pouvoir annuler les opérations en enregistrant leur contraire :

* une insertion correspond à une suppression
* une suppression correspond à une insertion
* un remplacement correspond à un remplacement
* un déplacement correspond à un déplacement

Donc, quand on veut inverser `ins 12 le nouveau mot`, on doit faire `rem 12-17`, car des espaces ont été ajoutées. C’est la difficulté, savoir exactement ce qui a été supprimé et inséré, il faut en faire le détail chaque fois, au cas par cas (je veux dire en voyant vraiment quel élément est ajouté ou supprimé).