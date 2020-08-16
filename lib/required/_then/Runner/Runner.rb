# encoding: UTF-8
require 'sqlite3'
require 'json'

module Runner
class << self
  attr_reader :itexte

  include ConfigModule

  # = main =
  #
  # Lancement de l'application
  #
  def run
    # On initialise le runner (pour le moment, ça vérifie seulement que
    # la table `lemmas` existe et ça la crée le cas échéant)
    init
    # On initialise le log (journal.log)
    Log.init
    # On prépare les fenêtres
    prepare_screen
    # On regarde le précédent texte édité, s'il existe
    config.load
    # Le chemin du fichier texte (ou projet Scrivener) à ouvrir
    fpath_to_open = nil
    if ARGV[0]
      fpath_to_open = ARGV[0]
      # Un premier argument définit le texte à ouvrir
      unless File.exists?(fpath_to_open)
        erreur("Le fichier #{fpath.inspect} est introuvable. Utiliser la commande ':open /path/to/file.txt' pour ouvrir un fichier existant.".freeze)
        return
      end
    end
    open_texte(fpath_to_open || config[:last_text_path] || File.join(APP_FOLDER,'asset','exemples','simple_text.txt'))
  rescue Exception => e
    log("Je dois exiter à cause de : #{e.message}")
    Curses.close_screen
    puts "#{e.message}#{RC}#{e.backtrace.join(RC)}".rouge
  end #/ run

  # Initialisation de l'application
  def init
    # Il faut s'assurer que la table `lemmas` existe. C'est la table qui
    # va contenir tous les mots possibles avec leur type et leur canon
    # correspondant. Chaque parsing de texte alimente cette table.
    res = Runner.db.execute("PRAGMA table_info('lemmas')")
    # Si res est vide, c'est que la table `lemmas` n'existe pas. Il faut donc
    # la construire.
    if res.empty?
      debug("* Contruction de la table `lemmas`")
      db.create_table_lemmas
      res = Runner.db.execute("PRAGMA table_info('lemmas')")
    end
  end #/ init

  # Pour ouvrir le texte de chemin d'accès +text_path+
  def open_texte text_path, commands = nil
    log("-> open_texte (text_path:#{text_path.inspect})")

    # Si un texte est présentement ouvert, il faut vérifier qu'il soit
    # bien sauvé. Et demander de le faire le cas échéant.
    unless @itexte.nil?
      check_if_current_texte_saved || return # annulation ou problème de sauvegarde
    end

    if File.exists?(text_path)
      @itexte = Texte.new(text_path)
      @iextrait = nil
      CWindow.textWind.clear
      if File.extname(text_path) == '.scriv' # Projet Scrivener
        log("-- Projet Scrivener --")
        extend ScrivenerModule
        projetscriv = Scrivener::Projet.new(text_path, @itexte)
        log("Projet Scrivener instancié.")
      else
        projetscriv = nil
      end
      config.data.merge!(last_text_path: text_path)
      log("Configuration enregistrée (:last_text_path)")
      if itexte.parse_if_necessary(projetscriv)
        log("👍 Projet OK (ou parsé avec succès)")
        # Tout s'est bien passé
        config.save
        show_extrait_and_wait_for_user
      else
        # Le parsing a rencontré des erreurs, on ne peut pas ouvrir
        # le texte.
        itexte.show_parsing_errors
        interact_with_user
      end
      config.save # à la toute fin
    else
      erreur("Le fichier “#{text_path}” est introuvable.")
      return false
    end
    return true
  end #/ open_texte

  # Retourne et conserve l'instance Texte du texte courant
  # Ce texte courant peut être soit un texte seul, soit un projet Scrivener
  def itexte
    @itexte
  end #/ itexte

  # L'extrait courant
  def iextrait
    @iextrait ||= begin
      # log("Instanciation @extrait (à partir de l'item #{itexte.current_first_item})")
      ExtraitTexte.new(itexte, index: itexte.current_first_item, index_is: :in_page)
    end
  end #/ iextrait
  def iextrait= extract
    @iextrait = extract
  end #/ iextrait= ext

  # Pour montrer un extrait
  # +params+ peut définir les choses de deux manières :
  #   a) avec un numéro de page (:numero_page)
  #   b) avec un index de mot (:from_index) absolu ou non.
  #
  def show_extrait(params)
    log("-> show_extrait(params:#{params.inspect})")
    @iextrait = ExtraitTexte.new(itexte, params)
    @iextrait.prepare # pour définir les listes
    @iextrait.output
    CWindow.init_status_and_cursor(clear:true)
  end #/ show_extrait

  # Méthode appelée quand on va quitter l'application (de façon normale, avec
  # la command “:q”)
  def finish
    check_if_current_texte_saved
    unless @itexte.nil?
      @itexte.db.finalize_all_statements
      @itexte.db.close
    end
  end #/ finish

  # Cette méthode, appelée quand on quitte l'application ou quand on
  # ouvre un autre texte, permet de vérifier que le texte courant ait
  # bien été sauvé. Mais depuis l'enregistrement systématique des modifications
  # ça n'est plus utile.
  def check_if_current_texte_saved
    return true
  end #/ check_if_current_texte_saved

  # Méthode principale qui affiche l'extrait courant au départ et attend
  # les commandes de l'utilisateur.
  # C'est aussi dans cette méthode que sont calculées les pages du texte en
  # fonction de la taille de l'écran.
  def show_extrait_and_wait_for_user
    log("-> show_extrait_and_wait_for_user")
    begin
      # On calcule les pages, en fonction des configurations actuelles
      # de l'écran.
      ProxPage.calcule_pages(itexte)
      # On affiche l'extrait courant du texte
      show_extrait(index: itexte.current_first_item, index_is: :in_page)
      interact_with_user
    rescue Exception => e
      Curses.close_screen
      erreur("ERROR: #{e.message}#{RC}#{e.backtrace.join(RC)}")
      erreur(e)
    else
      Curses.close_screen
    end
  end #/ show_extrait_and_wait_for_user

  # Méthode qui prépare l'écran du Terminal pour recevoir les
  # trois fenêtres :
  #   - celle du texte    CWindow.textWin
  #   - celle du statut   CWindow.statusWin
  #   - interactif        CWindow.uiWin
  def prepare_screen
    CWindow.prepare_windows
  end #/ prepare_screen

# ---------------------------------------------------------------------
#   Pour la configuration
# ---------------------------------------------------------------------
def config_default_data
  @config_default_data ||= {
    last_text_path: nil,
    last_opening: Time.now.to_i
  }
end #/ config_default_data
def config_path
  @config_path ||= File.join(APP_FOLDER,'config','config.json')
end #/ config_path

# Pour la gestion de la base de données propre à New Proximité. Elle contient
# notamment la table `lemmas` qui permet de retrouver n'importe quel canon et
# enregistre les nouveaux.
#
# Les deux méthodes principales sont
#   Pour récupérer un canon : `Runner.get_canon(<mot>)`
#   Pour enregistrer un canon : `Runner.add_mot_and_canon(mot, type, canon)`
def db
  @db ||= TextSQLite.new(self)
end #/ db
def db_path
  @db_path ||= File.join(APP_FOLDER,'lib','data.db')
end #/ db_path
end #/<< self
end #/Runner
