## Définition des constantes de proximité

### Constante de proximité minimale

La constante la plus importante, dans proximité, est la distance
minimale sous laquelle deux mots seront en trop grande proximité.

Par défaut, elle est réglée à 1500 signes (une page de distance,
mais cette distance est très « absolue ». La plupart des grands
textes ne supporteraient pas cette distance). On peut l'ajuster au
texte courant à l'aide de la commande :

`:set distance_minimale_commune <valeur>`

Où `<valeur>` est un nombre quelconque définissant le nombre de
signes qui doivent séparer au minimum deux mots pour qu'ils ne
soient pas en trop grande proximité.

Plus ce nombre est petit, et moins les mots seront en proximité.
Plus il est grand et plus ils risqueront de l'être. Il faut compren-
dre cette valeur comme :

« Si un mot se trouve à moins de <valeur> signes d'un mot de même
  canon avant, il sera en proximité avec ce mot. »

Pour connaitre la valeur de la distance minimale commune, on peut
jouer la commande :

`:get distance_minimale_commune`

Mais on notera que cette distance est inscrite dans la bande de
statut, après la marque “Dist:”.

### Listes spéciales

Pour les listes spéciales, par exemple les listes de mots qu'il faut
exclure de l'analyse de proximité, voir le texte d'aide suivant ou
taper, hors de l'aide, la commande `:h[elp] Listes` (avec le “L” ma-
juscule).
