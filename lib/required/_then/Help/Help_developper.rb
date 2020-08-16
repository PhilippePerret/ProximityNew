# encoding: UTF-8
=begin
  Aide pour le développeur
=end
class Help
AIDE_DEVELOPPER_STRING = <<-EOT
=== AIDE POUR LE DÉVELOPPEUR ===

Messages dans les journaux
---------------------------

Pour tester les valeurs du programme, on peut utiliser dans la console
les commandes-méthodes `:debug(...)` et `:log(...)` qui écrivent respec-
tivement dans les fichiers `debug.log` et `journal.log`.

Noter que pour le log, pour le moment — journal.log — il faut quitter
l'application pour être en mesure de lire le journal. Ce qui n'est pas le
cas avec `debug(...)` qu'il est donc préférable d'utiliser.

Par exemple :

    :debug(ProxPage.current_page.inspect)
    # => met dans debug.log l'inspection de la page courante affichée
    
EOT

class << self

end # /<< self
end #/Help
