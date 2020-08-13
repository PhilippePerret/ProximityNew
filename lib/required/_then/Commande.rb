# encoding: UTF-8
class Commande
class << self
  # Jouer la commande voulue
  def run(cmd)
    log("🔨 Commande jouée : #{cmd.inspect}")
    historize(cmd)
    cmd_init = cmd.dup.freeze
    cmd = cmd.split(SPACE)
    cmd_name = cmd.shift

    # *** Analyse de la commande ***

    case cmd_name

    when 'essai'
      # Pour faire des essais et les lancer par ":essai"


    when 'canon'
      mot = cmd.shift
      canon = Runner.db.get_canon(mot)
      if canon
        log("Le canon enregistré de #{mot.inspect} est #{canon.inspect}", true)
      else
        log("Le mot #{mot.inspect} n'a pas de canon enregistré dans Proximity.", true)
      end


    when 'rebuild' # reconstruire le texte final
      Runner.itexte.rebuild


    when 'cancel', 'annuler'

      erreur("Pour le moment, on ne peut pas encore annuler.")
      # Runner.itexte.cancellor.ask_for_cancel_last

    when 'eval'
      code = cmd.join(SPACE)
      begin
        eval(code)
      rescue Exception => e
        CWindow.error(e.message)
        log("ERROR EVAL: #{e.message}#{RC}#{e.backtrace.join(RC)}")
      end


    when 'debug'
      # La commande 'debug' permet de débugger beaucoup de choses dans
      # le programme.
      what = cmd.shift
      case what
      when 'item', 'mot'
        item_index = cmd.shift.to_i
        item = Runner.itexte.items[item_index]
        msg = "DEBUG item #{item_index} : #{item.debug(output: :console)}".freeze
        debug(msg)
        debug(item.inspect)
        CWindow.log("#{msg} (détails dans debug.log)")
      when 'mots'
        debug("#{RC*2}Débuggage des mots du texte".freeze)
        entete = "#{RC} #{'index'.ljust(7)}#{'Contenu'.ljust(15)}#{'Offset'.ljust(8)}#{'FileId'.ljust(7)}".freeze
        debug(entete)
        debug(('-'*entete.length).freeze)
        Runner.itexte.items.each do |titem|
          debug(titem.debug)
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
        # Si un argument est fourni, c'est le chemin d'accès au nouveau
        # texte à ouvrir.
        Runner.open_texte(what, cmd)
      end


    when 'recompte' # Recompte tout le texte (fait automatiquement, normalement)
      Runner.itexte.recompte


    when 'update', 'reprepare' # pour forcer la repréparation du texte
      confirmation = cmd.shift
      if confirmation == '--confirmed' || confirmation == '--force'
        if Runner.itexte.parse # maintenant, reprend tout
          # On ne passe à l'affichage que si le parsing s'est bien déroulé
          CWindow.textWind.write(Runner.iextrait.output)
        end
      else
        CWindow.log("Ajouter --confirmed à la commande pour confirmer l'opération, qui va DÉTRUIRE TOUTES LES TRANSFORMATIONS déjà opérées pour repartir du texte initial.")
      end

    when 'ref', 'refresh'
      # Pour rafraichir l'affichage
      CWindow.textWind.write(Runner.iextrait.output)
      CWindow.log("L'affichage a été rafraichi. Ça va mieux ?".freeze)


      # *** Toutes les méthodes de modification du texte ***

    when 'try'
      # Forme de la commande :try <cmd> <index> <content>
      ope = cmd.shift
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.essayer(operation:ope, content:texte, at:index_ref, cancellor:@operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'ign'
      index_ref = cmd.shift
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.ignore(at: index_ref, cancellor: @operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'inj' # Ré-injecter un mot ignoré
      index_ref = cmd.shift
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.unignore(at: index_ref, cancellor: @operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'sup', 'del', 'rem'
      index_ref = cmd.shift
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.remove(at:index_ref, cancellor: @operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'ins', 'insert'
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.insert(content:texte, at:index_ref, cancellor:@operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'rep', 'replace'
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.replace(content:texte, at:index_ref, cancellor:@operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

      # *** Méthodes d'affichage ***

    when 'show'
      from = cmd.shift.to_s
      Runner.itexte.update if Runner.iextrait.modified
      pms = {index: nil, index_is: nil}
      if from.end_with?('*')
        pms[:index]     = from[0...-1].to_i + Runner.iextrait.from_item
        pms[:index_is]  = :absolu # oui car rendu absolu ci-dessus
      elsif from.end_with?('p')
        pms[:index] = from[0...-1].to_i
        pms[:index_is] = :in_page
      else
        pms[:index] = from.to_i
        pms[:index_is] = :absolu
      end
      pms[:index] = 0 if pms[:index] < 0
      Runner.show_extrait(pms)

    when 'next'
      what = cmd.shift
      case what
      when 'page'
        if Runner.iextrait.page.numero == ProxPage.last_numero_page
          CWindow.log("C'est la dernière page !".freeze)
        else
          Runner.itexte.update if Runner.iextrait.modified
          Runner.show_extrait(numero_page: Runner.iextrait.page.numero + 1)
        end
      end

    when 'prev'
      what = cmd.shift
      case what
      when 'page' #  prev page
        if Runner.iextrait.page.numero == 1
          CWindow.log("C'est la première page !".freeze)
        else
          Runner.itexte.update if Runner.iextrait.modified
          Runner.show_extrait(numero_page: Runner.iextrait.page.numero - 1)
        end
      end

      # *** Commandes d'information ***

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


    when 'add', 'remove'
      # Pour ajouter un item à une liste prorpre, le plus souvent, comme
      # la liste des mots apostrophes.
      what  = cmd.shift
      value = cmd.join(SPACE)
      case what
      when 'mot_tiret', 'mot_apostrophe', 'mot_sans_prox'
        Runner.itexte.send("#{cmd_name}_#{what}".to_sym, value)
      else
        erreur("Je ne sais pas comment ajouter un/e #{what}")
      end

    when 'help'
      Runner.display_help


    when 'copy'
      what = cmd.shift
      Runner.copy(what, cmd)

    else

      CWindow.log("Command inconnue : “#{cmd_init}”".freeze)
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
