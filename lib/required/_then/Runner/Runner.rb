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



  # Pour ouvrir le texte de chemin d'accès +text_path+
  def open_texte text_path, commands = nil
    log("-> open_texte (text_path:#{text_path.inspect})")
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
      log("Instanciation @extrait (à partir de l'item #{itexte.current_first_item})")
      ExtraitTexte.new(itexte, from: itexte.current_first_item)
    end
  end #/ iextrait
  def iextrait= extract
    @iextrait = extract
  end #/ iextrait= ext

  # Pour montrer un extrait
  def show_extrait(from)
    self.iextrait = ExtraitTexte.new(itexte, from: from)
    self.iextrait.output
  end #/ show_extrait

  # Pour afficher l'aide
  def display_help(options = nil)
    Help.show(options)
  end #/ display_help

  def show_extrait_and_wait_for_user
    begin
      # On affiche l'extrait courant du texte
      iextrait.output
      interact_with_user
    rescue Exception => e
      Curses.close_screen
      erreur("ERROR: #{e.message}#{RC}#{e.backtrace.join(RC)}")
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

end #/<< self
end #/Runner
