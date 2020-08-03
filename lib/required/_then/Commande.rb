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
    when 'debug'
      what = cmd.shift
      case what
      when 'item'
        item_index = cmd.shift.to_i
        item = Runner.itexte.items[item_index]
        log("DEBUG item #{item_index} : #{item.inspect}")
        CWindow.log("DEBUG item #{item_index} : #{item.to_s}")
      end
    when 'open' # ouvrir un nouveau texte avec son path
      what = cmd.shift
      Runner.open_texte(what, cmd)
    when 'recompte' # Recompte tout le texte (fait automatiquement, normalement)
      Runner.itexte.recompte
    when 'ref', 'refresh'
      # Pour rafraichir l'affichage
      CWindow.textWind.write(Runner.iextrait.output)

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
    when 'reprox'
      if cmd.shift == '--force'
        # On peut le faire puisque ça a été confirmé
        Runner.itexte.reproximitize
        log("Commande : reprox (relancer le calcul de proximité)")
      else
        CWindow.uiWind.write("Attention, cette opération va détruire tous les changements opérés à tout jamais. Ajouter `--force` à la commande pour confirmer que vous voulez tout perdre et repartir à zéro.")
      end
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
