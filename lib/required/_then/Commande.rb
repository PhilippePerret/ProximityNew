# encoding: UTF-8
class Commande
class << self
  # Contient l'historique des messages
  # Mis en public pour les tests
  attr_reader :historique

  # Jouer la commande voulue
  def run(cmd)
    log("♻︎ Commande jouée : #{cmd.inspect}")

    # Certaines commandes sont des raccourcis qu'il faut étendre
    case cmd
    when /^debug\(/,  /^log\(/
      cmd = "eval #{cmd}"
      CWindow.log("Consulter #{cmd.match?(/^debug\(/) ? 'debug' : 'journal'}.log pour voir le résultat (quitter pour journal.log).")
      log("♻︎ Commande rectifiée : #{cmd.inspect}")
    end

    # On peut maintenant traiter la commande
    historize(cmd)
    cmd_init = cmd.dup.freeze
    cmd = cmd.split(SPACE)
    cmd_name = cmd.shift

    # *** Analyse de la commande ***

    case cmd_name


    when 'essai'
      # Pour faire des essais et les lancer par ":essai"

      color1 = cmd.shift.to_i
      color2 = cmd.shift.to_i
      color3 = cmd.shift.to_i
      log("can_change_color? #{Curses.can_change_color?.inspect}", true)
      log("Curses.has_colors? #{Curses.has_colors?.inspect}", true)
      nombre_couleurs = Curses.colors
      log("Nombre couleurs : #{nombre_couleurs.inspect}")

      (0..1000).step(100) do |color1|
        (0...nombre_couleurs).each do |icolor|
          CWindow.log("Couleur index #{icolor} / color #{color1} / ")
          sleep 0.5
          # Curses.init_color(icolor, color1, 0, 0)
          Curses.init_pair(1, icolor, icolor)
        end
      end

    when 'next'
      what = cmd.shift
      case what
      when 'page'
        if Runner.iextrait.page.numero == ProxPage.last_numero_page
          CWindow.log("C'est la dernière page !".freeze)
        else
          Runner.show_extrait(numero_page: Runner.iextrait.page.numero + 1)
        end
      else
        erreur("Je ne sais pas traiter le 'next' de '#{what}'.")
      end

    when 'prev'
      what = cmd.shift
      case what
      when 'page' #  prev page
        if Runner.iextrait.page.numero == 1
          CWindow.log("C'est la première page !".freeze)
        else
          Runner.show_extrait(numero_page: Runner.iextrait.page.numero - 1)
        end
      end


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
        item_index = cmd.shift
        if item_index.end_with?('*')
          item_index = item_index[0...-1].to_i
          titem = Runner.itexte.get_titem_by_index(item_index)
        else
          item_index = item_index.to_i
          titem = Runner.iextrait.extrait_titems[item_index]
        end
        if titem.nil?
          erreur("L'item d'index relatif #{item_index} est inconnu. Pour un index absolu, ajouter une étoile après le l'index — p.e. '#{item_index}*'.")
        else
          msg = "DEBUG item #{item_index} : #{titem.debug(output: :console)}".freeze
          debug(msg)
          debug(titem.inspect)
          CWindow.log("#{msg} (détails dans debug.log)")
        end
      when 'mots'
        debug("#{RC*2}Débuggage des mots du texte".freeze)
        entete = "#{RC} #{'index'.ljust(7)}#{'Contenu'.ljust(15)}#{'Offset'.ljust(8)}#{'FileId'.ljust(7)}".freeze
        debug(entete)
        debug(('-'*entete.length).freeze)
        Runner.iextrait.extrait_titems.each do |titem|
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
      when 'pages'
        debug(RC*3)
        debug("=== DEBUG DES PAGES ===")
        ProxPage.pages.each do |numero, page|
          debug(page.debug)
        end
        CWindow.log("Pages débugguées dans le fichier debug.log")
      else
        erreur("Je ne sais pas débugger “#{what}”")
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

    when 'sup', 'del', 'rem', '-'
      index_ref = cmd.shift
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.remove(at:index_ref, cancellor: @operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'ins', 'insert', '+'
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.insert(content:texte, at:index_ref, cancellor:@operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'rep', 'replace', '='
      index_ref = cmd.shift
      texte = cmd.join(SPACE)
      @operation_cancellor = OpeCancellor.new(cmd_init)
      Runner.iextrait.replace(content:texte, at:index_ref, cancellor:@operation_cancellor)
      Runner.itexte.cancellor.add_and_save(@operation_cancellor)

    when 'occ', 'occurence'
      mot_ref = cmd.join(SPACE)
      mot_ref = Runner.iextrait.extrait_titems[mot_ref.to_i] if mot_ref.numeric?
      Runner.itexte.show_occurences_of(mot_ref)

      # *** Méthodes d'affichage ***

    when 'show'
      from = cmd.shift.to_s
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

    when 'help', 'aide', 'h'
      # Affichage de l'aide
      # On envoie la commande car si le deuxième mot est "dev" ou "developper"
      # on va afficher l'aide pour ça. Sinon, ça peut aussi être l'aide
      # précise sur un élément.
      Help.show(cmd)

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
    @historique_index = @historique.count
      # On ne met pas à count - 1 pour pouvoir rappeler la commande courante
      # en faisant back_historique
  end #/ historize

  # Pour aller à la commande historisée suivante
  def up_historique
    if @historique_index == @historique.count
      CWindow.log("C'est la toute dernière commande !")
    else
      show_commande_historized(@historique_index + 1)
    end
  end #/ up_historique

  # Pour revenir à la commande historisée précédente
  def back_historique
    if @historique_index == 0
      CWindow.log("C'est toute première commande !")
    else
      show_commande_historized(@historique_index - 1)
    end
  end #/ back_historique

  # Méthode qui réaffiche une commande précédente et la renvoie
  # Note : la commande est renvoyée car Runner (interact) a besoin
  # de la connaitre pour pouvoir la modifier correctement.
  def show_commande_historized(cmd_idx)
    commande = @historique[@historique_index = cmd_idx]
    wind  = CWindow.uiWind
    wind.resetpos
    wind.write(":#{commande}".freeze)
    Runner.reset_mode_clavier

    return commande
  end #/ show_commande_historized

end # /<< self
end #/Commande
