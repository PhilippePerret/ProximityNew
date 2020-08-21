## La Base de données

Le nouveau fonctionnement complet inauguré le 11 août est le suivant :

* on utilise la base propre au texte `db.sqlite` (table `text_items` pour enregistrer tous les mots,
* on utilise la base de l'application (table `lemmas`) pour enregistrer seulement mot unique, type et canon,
* on utilise une table générale pour chaque texte (table `infos`) pour les données générales, par exemple l’identifiant ou l’index du premier mot du panneau courant.
* on utilise une table provisoire qui contient toutes les informations du panneau courant, à commencer par tous les mots.

### Parsing complet du texte

Au cours du parsing complet du texte, les mots sont enregistrés dans la base `db.sqlite` du dossier prox du texte — par paquet de x mots (5000 au moment de l’écriture de ce texte). On renseigne également la table `lemmas` de l’application qui contient « un mot = un canon » (avec le type et un canon alternatif) qui permettra d’obtenir plus tard un grand nombre de canons sans passer par TreeTagger (grâce à la méthode `Texte.db.get_canon("<mot>")`).

Au cours du parsing, pour ne pas répéter les appels à la table `lemmas` pour savoir si un mot est déjà enregistré, on tient à jour, une table `Hash` `PARSED_LEMMAS`  liste les mots déjà traités dans leur forme exacte. Cette table contient par exemple :

~~~ruby
PARSED_LEMMAS = {
  # ...
  "seraient" => "être",
  "sera" => "être",
  # ...
 }
~~~
