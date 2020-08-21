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
