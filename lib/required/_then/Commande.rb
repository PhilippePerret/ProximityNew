# encoding: UTF-8
class Commande
class << self
  # Jouer la commande voulue
  def run(cmd)
    log("Commande jouée : #{cmd.inspect}")
    historize(cmd)
    cmd_init = cmd.dup.freeze
    cmd = cmd.split(SPACE)
    cmd_name = cmd.shift
    case cmd_name
    when 'rebuild' # reconstruire le texte final
      Runner.itexte.rebuild
    when 'eval'
      code = cmd.join(SPACE)
      begin
        eval(code)
      rescue Exception => e
        CWindow.error(e.message)
        log("ERROR EVAL: #{e.message}#{RC}#{e.backtrace.join(RC)}")
      end
    when 'debug'
      what = cmd.shift
      case what
      when 'item', 'mot'
        item_index = cmd.shift.to_i
        item = Runner.itexte.items[item_index]
        msg = "DEBUG item #{item_index} : #{item.cio} (canon: #{item.canon.inspect})".freeze
        debug(msg)
        CWindow.log(msg)
      when 'mots'
        debug("#{RC*2}Débuggage des mots du texte".freeze)
        Runner.itexte.items.each do |titem|
          debug("#{titem.index.to_s.ljust(7)}#{titem.cio}")
        end
        debug("#{RC*2}".freeze)
        CWindow.log("Mots débuggués dans debug.log.")
      when 'canon'
        canon = cmd.shift
        debug("#{RC*2}-- canon #{canon} --")
        icanon = Canon.items_as_hash[canon]
        if icanon.nil?
          CWindow.log("Aucune information canonique pour #{canon.inspect}")
        else
          icanon.items.each {|item| debug(item.cio) }
          CWindow.log("Canon de #{canon} écrits dans debug.log.")
        end
      when 'canons'
        # Pour écrire les canons en log
        debug(RC*3)
        Canon.items_as_hash.each do |can, ican|
          debug("-- canon #{can} --")
          ican.items.each {|item| debug(item.cio) }
        end
        CWindow.log("Canons écrits dans debug.log.")
      end
    when 'open' # ouvrir un nouveau texte avec son path
      what = cmd.shift
      if what.nil?
        # Si aucun argument n'est passé, il faut ouvrir le dossier du texte
        # courant
        `open -a Finder "#{Runner.itexte.folder}"`
      else
        # Si un argument est passé, c'est le chemin d'accès au nouveau
        # texte à ouvrir.
        Runner.open_texte(what, cmd)
      end

    when 'recompte' # Recompte tout le texte (fait automatiquement, normalement)
      Runner.itexte.recompte

    when 'reprepare', 'update' # pour forcer la repréparation du texte
      confirmation = cmd.shift
      if confirmation == '--confirmed' || confirmation == '--force'
        Runner.itexte.reproximitize
        CWindow.textWind.write(Runner.iextrait.output)
      else
        CWindow.log("Ajouter --confirmed à la commande pour confirmer l'opération, qui va DÉTRUIRE TOUTES LES TRANSFORMATIONS déjà opérées pour repartir du texte initial.")
      end
    when 'ref', 'refresh'
      # Pour rafraichir l'affichage
      CWindow.textWind.write(Runner.iextrait.output)
      CWindow.log("L'affichage a été rafraichi. Ça va mieux ?".freeze)

      # *** Toutes les méthodes de modification du texte ***

    when 'sup', 'del', 'delete', 'rem', 'remove'
      index_ref = cmd.shift
      Runner.iextrait.remove(at:index_ref)
    when 'ins', 'insert'
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      Runner.iextrait.insert(content:texte, at:index_ref)
    when 'rep', 'replace'
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      Runner.iextrait.replace(content:texte, at:index_ref)
      # *** Méthodes d'affichage ***
    when 'show'
      from = cmd.shift.to_i
      Runner.iextrait = ExtraitTexte.new(Runner.itexte, from: from)
      Runner.iextrait.output
    when 'next'
      what = cmd.shift
      case what
      when 'page'
        from = Runner.iextrait.to_item + 1
        Runner.iextrait = ExtraitTexte.new(Runner.itexte, from: from)
        Runner.iextrait.output
      end
    when 'prev'
      what = cmd.shift
      case what
      when 'page' #  prev page
        from = Runner.iextrait.from_item - 150
        from = 0 if from < 0
        Runner.show_extrait(from)
      end
    when 'get'
      what = cmd.shift
      case what
      when 'distance_minimale_commune'
        CWindow.log("La :distance_minimale_commune du texte courant vaut #{Runner.itexte.distance_minimale_commune}.")
      else
        CWindow.error("Je ne comprends pas la valeur '#{what}'")
      end
    when 'set'
      what = cmd.shift
      val  = cmd.join(SPACE)
      case what
      when 'distance_minimale_commune'
        val = val.to_i
        val = DISTANCE_MINIMALE_COMMUNE if val == 0
        Runner.itexte.config.save(distance_minimale_commune: val)
        Runner.itexte.reset(:distance_minimale_commune)
        CWindow.log("distance_minimale_commune du texte mis à #{val}")
        Canon.each { |can| can.reset }
        Runner.iextrait.update
      else
        CWindow.error("Je ne sais pas régler '#{what}'")
      end
    when 'reprox'
      if cmd.shift == '--force'
        # On peut le faire puisque ça a été confirmé
        Runner.itexte.reproximitize
        log("Commande : reprox (relancer le calcul de proximité)")
      else
        CWindow.uiWind.write("Attention, cette opération va détruire tous les changements opérés à tout jamais. Ajouter `--force` à la commande pour confirmer que vous voulez tout perdre et repartir à zéro.")
      end
    when 'help'
      Runner.display_help
    else
      CWindow.log("Command inconnue : “#{cmd_init}”")
      @historique.pop # on la supprime de l'historique
    end
  end #/ run

  # Mémoriser la commande
  def historize(command)
    @historique ||= []
    @historique << command
  end #/ historize

end # /<< self
end #/Commande
