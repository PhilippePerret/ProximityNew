# encoding: UTF-8
module ProximityNew
class << self
  def itexte
    @itexte ||= begin
      log("Instanciation de @itexte")
      Texte.new(ARGV[0] || File.join(APP_FOLDER,'asset','exemples','simple_text.txt'))
    end
  end #/ itexte
  def iextrait
    @iextrait ||= begin
      log("Instanciation @extrait")
      ExtraitTexte.new(itexte, {from: itexte.current_first_item})
    end
  end #/ iextrait
  def run
    itexte.parse_if_necessary

    # On prépare les fenêtres
    prepare_screen

    begin
      iextrait.output
      CWindow.uiWind.write("Taper “:help” pour obtenir de l’aide. Pour quitter : “:q”")
      CWindow.uiWind.watch
    rescue Exception => e
      Curses.close_screen
      puts "ERROR: #{e.message}#{RC}#{e.backtrace.join(RC)}"
    else
      Curses.close_screen
    end

  end #/ run


  # Méthode qui prépare l'écran du Terminal pour recevoir les
  # trois fenêtres :
  #   - celle du texte    CWindow.textWin
  #   - celle du statut   CWindow.statusWin
  #   - interactif        CWindow.uiWin
  def prepare_screen
    CWindow.prepare_windows
  end #/ prepare_screen

end #/<< self
end #/ProximityNew
