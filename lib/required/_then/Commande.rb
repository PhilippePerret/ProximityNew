# encoding: UTF-8
class Commande
class << self
  def run(cmd)
    cmd = cmd.split(SPACE)
    cmd_name = cmd.shift
    case cmd_name
    when 'ref', 'refresh'
      # Pour rafraichir l'affichage
      CWindow.textWind.write(Runner.iextrait.output)
    when 'ins', 'insert'
      where = cmd.shift
      where_index = cmd.shift
      texte = cmd.join(SPACE)
      log("Insérer le texte “#{texte}”")
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
    end
  end #/ run

end # /<< self
end #/Commande
