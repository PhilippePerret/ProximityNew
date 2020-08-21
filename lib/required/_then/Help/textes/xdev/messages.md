## Messagerie

Trois journaux permettent de recevoir des messages de l'application :

* `journal.log` qui reçoit les messages commun et se réinitialise à
  chaque session,
* `debug.log` qui reçoit les messages de débuggage, et reste toujours
  en place.
* `error.log` qui reçoit les erreurs programmes.

Ces trois journaux se trouvent dans le dossier `./logs` de l'applica-
tion.

Noter qu'il faut quitter l'application pour pouvoir lire le fichier
`journal.log`, ce qui n'est pas le cas pour les deux autres fichiers.

On peut envoyer un message dans le fichier `journal.log` à l'aide de
la commande `log("Mon message")`. Noter que si on met `true` en se-
cond paramètre le message s'affiche également dans la fenêtre de
l'application.

On peut envoyer un message dans le fichier `debug.log` à l'aide de la
commande de même nom : `debug("Le message à débugguer")`.
