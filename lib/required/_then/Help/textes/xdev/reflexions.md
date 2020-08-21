## Annexe

### Réflexions

#### Concernant les annulations

Pouvoir annuler les opérations en enregistrant leur contraire :

* une insertion correspond à une suppression
* une suppression correspond à une insertion
* un remplacement correspond à un remplacement
* un déplacement correspond à un déplacement

Donc, quand on veut inverser `ins 12 le nouveau mot`, on doit faire `rem 12-17`, car des espaces ont été ajoutées. C’est la difficulté, savoir exactement ce qui a été supprimé et inséré, il faut en faire le détail chaque fois, au cas par cas (je veux dire en voyant vraiment quel élément est ajouté ou supprimé).
