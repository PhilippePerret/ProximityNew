## Commandes utiles

Cette section présente les commandes les plus utiles et les plus uti-
lisées avec l'application Proximity.

Ci-dessous, tous les <index> peuvent être indiqués de trois manières
différentes :

  * index simple    p.e. '12'
  * range d'index   p.e. '12-23' (i.e. de 12 à 23)
  * liste d'index   p.e. '12,14,23' (sans espaces)

Les index se voient toujours par rapport à la page affichée.

`:rep <index> <texte>`
`:= <index> <texte>`

    Permet de REMPLACER le texte à <index> par le texte
    <texte>.

`:ins <index> <texte>`
`:+ <index> <texte>`

    Permet d'INSÉRER le texte <texte> à l'index <index>. Ici, <index>
    est forcément un nombre simple.

`:rem <index>`
`:- <index> <texte>`
`:del <index>`
`:sup <index>`

    Permet de SUPPRIMER le texte défini par <index>.

Note : toutes ces opérations sont enregistrées dans la table `operations` et permettent d'être retrouvées.

`:ign <index>`

    Permet d'IGNORER le mot d'index <index>. Ignorer un mot signifie
    qu'il ne sera pas considéré lors des analyses de proximité.
    Noter que cela ne concerne QUE le mot d'index spécifié et aucun
    des autres mots similaires. Pour supprimer tous les mots simi-
    laires, il faut rentrer le mot dans la liste des mots à retirer.
