## Annexe

### Index

Dans PROXIMITY, chaque text-item (*) de la page affichée est accompa-
gné de son index qui correspond à son décalage dans la page à partir
de zéro (0). Cet index est donc principalement relatif à la page af-
fichée ce qui permet, même pour les textes longs, de garder une
désignation courte, la page pouvant afficher suivant l'interface de
200 à 400 text-items.

(*) On parle de “text-items” plutôt que de “mots” car Proximity trai-
    te des mots aussi bien que les non-mots que sont les ponctuations
    ou les espaces.

Pour définir l'index dans une commande — par exemple pour insérer,
pour supprimer, pour remplacer, nous avons à disposition trois moyens
différents :

* **L'index unique**. '12' par exemple définira le 12e mot dans la page
  actuellement affichée. Par exemple, la commande `:rem 12` signi-
  fiera : “supprimer le 12e text-item” (qui peut être un mot ou une
  ponctuation).

* **Le Rang d'index**. Un rang d'index (“range” en anglais) se défi-
  par un premier nombre suivi d'un tiret et terminé par un second
  nombre de fin. Par exemple '12-14'. Cet exemple définit les text-
  items de 12 à 14 dans la page courante.
  La commande `:rep 12-14 bonjour tout le monde` signifie qu'il faut
  remplacer les text-items de 12 à 14 par “bonjour tout le monde”.
  Noter que le nombre de text-items remplacés (3 ici) n'a pas du tout
  besoin d'être identique au nombre de mots de remplacement.

* **La Liste d'index**. Une liste d'index se définit par une liste de
  nombres séparés par des virgules, mais sans aucune espace. Par
  exemple : "12,14,17" qui concernera les text-items d'index 12, 14
  et 17 dans la fenêtre courante. La commande `:rem 12,14,17` signi-
  fiera “Détruire les text-items 12, 14 et 17.”
