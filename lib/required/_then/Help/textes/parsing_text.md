## Aide sur le parsing

Le parsing consiste à donner un texte à l'application et que celle-ci
la découpe en text-items qui pourront ensuite être analysés et modi-
fiés.

Le parsing est automatiquement lancé quand un nouveau texte est
fourni à l'application, sauf si ce texte a déjà été analysé (dans ce
cas, il possède un dossier proximity qui porte comme nom l'affixe
du nom du fichier du texte auquel est ajouté '_prox')

Le parsing du texte peut être relancé en utilisant la commande :

`:update --force`
