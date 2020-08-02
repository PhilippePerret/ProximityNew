# encoding: UTF-8
require 'json'

module Runner
class << self
  include ConfigModule

  def itexte
    @itexte ||= begin
      log("Instanciation de @itexte")
      path_text = ARGV[0] || config[:last_text_path] || File.join(APP_FOLDER,'asset','exemples','simple_text.txt')
      CWindow.log("Texte à charger : #{path_text}")
      Texte.new(path_text)
    end
  end #/ itexte

  # L'extrait courant
  def iextrait
    @iextrait ||= begin
      log("Instanciation @extrait")
      ExtraitTexte.new(itexte, {from: itexte.current_first_item})
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
  
  # = main =
  #
  # Lancement de l'application
  #
  def run

    # On prépare les fenêtres
    prepare_screen

    # On regarde le précédent texte édité, s'il existe
    config.load

    if ARGV[0]
      # Un premier argument définit le texte à ouvrir
      if File.exists?(ARGV[0])
        config.data.merge!(last_text_path: ARGV[0])
        config.save
      else
        ARGV[0] = nil
      end
    end

    # On parse le texte
    itexte.parse_if_necessary

    begin
      # On affiche l'extrait du texte
      iextrait.output rescue nil
      CWindow.uiWind.write("Taper “:help” pour obtenir de l’aide. Pour quitter : “:q”")
      CWindow.uiWind.watch
    rescue Exception => e
      Curses.close_screen
      puts "ERROR: #{e.message}#{RC}#{e.backtrace.join(RC)}"
    else
      Curses.close_screen
    end

    # À la fin, on sauve la configuration courante
    config.save

  end #/ run


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
