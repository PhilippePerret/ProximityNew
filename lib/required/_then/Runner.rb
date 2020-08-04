# encoding: UTF-8
require 'sqlite3'
require 'json'

module Runner
class << self
  include ConfigModule

  # Retourne et conserve l'instance Texte du texte courant
  # Ce texte courant peut être soit un texte seul, soit un projet Scrivener
  def itexte
    @itexte ||= begin
      log("Instanciation de @itexte")
      path_text = ARGV[0] || config[:last_text_path] || File.join(APP_FOLDER,'asset','exemples','simple_text.txt')
      log("Texte à charger : #{path_text}")
      CWindow.log("Texte à charger : #{path_text}")
      Texte.new(path_text)
    end
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

  # Pour ouvrir le texte de chemin d'accès +text_path+
  def open_texte text_path, commands = nil
    if File.exists?(text_path)
      if File.extname(text_path) == '.scrivx'
        extend ScrivenerModule
        Scrivener::Projet.open(text_path)
      elsif File.extname(text_path) == '.scriv'
        extend ScrivenerModule
        affixe = File.basename(text_path, File.extname(text_path))
        Scrivener::Projet.open(File.join(text_path,"#{affixe}.scrivx"))
      end
      config.data.merge!(last_text_path: text_path)
      config.save
    else
      CWindow.error("Le fichier “#{text_path}” est introuvable.")
      return
    end

  end #/ open_texte

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
        open_texte(ARGV[0])
      else
        ARGV[0] = nil
      end
    end

    # On parse le texte
    itexte.parse_if_necessary || begin
      CWindow.log "Problème en parsant le fichier. Je dois renoncer. Taper ':open path/to/file' pour ouvrir un autre fichier."
      Runner.interact_with_user
      return
    end

    begin
      # On affiche l'extrait courant du texte
      iextrait.output rescue nil
      CWindow.uiWind.write("Taper “:help” pour obtenir de l’aide. Pour quitter : “:q”")
      Runner.interact_with_user
    rescue Exception => e
      Curses.close_screen
      puts "ERROR: #{e.message}#{RC}#{e.backtrace.join(RC)}"
    else
      Curses.close_screen
    end

    # À la fin, on sauve la configuration courante
    config.save

  end #/ run


  def interact_with_user
    wind  = CWindow.uiWind
    curse = wind.curse # raccourci
    start_command = false # mis à true quand il tape ':'
    command = nil
    while true
      # On attend sur la touche de l'utilisateur
      s = curse.getch
      case s
      when 10 # Touche retour => soumission de la commande
        log("Soumission de la commande #{command.inspect}")
        case command
        when 'q'
          break
        else
          wind.clear
          begin
            Commande.run(command)
          rescue Exception => e
            log("ERROR COMMANDE : #{e.message}#{RC}#{e.backtrace.join(RC)}")
            CWindow.error("Une erreur fatale est survenue (#{e.message}). Quitter et consulter le journal de bord.")
          end
        end
      when 194, 195, 226
        s3 = gestion_touches_speciales(s)
        if start_command
          command << s3
          wind.clear
          wind.write(":#{command}")
        end
      when 27 # Escape button
        start_command = false
        command = ""
        wind.clear
        wind.write(EMPTY_STRING)
      when ':'
        start_command = true
        command = ""
        wind.resetpos
        wind.write(':')
      when 261 # RIGHT ARROW
        if iextrait.to_item + 1 >= itexte.items.count
          CWindow.log("C'est la dernière page !".freeze)
        else
          Commande.run('next page')
        end
      when 260 # LEFT ARROW
        if iextrait.from_item == 0
          CWindow.log("C'est la première page !".freeze)
        else
          Commande.run('prev page')
        end
      when 258 # BOTTOM ARROW
        wind.write("Aller en bas")
      when 259 # TOP ARROW
        wind.write("Aller en haut")
      when 127 # effacement arrière
        if start_command
          command = command[0...-1]
          wind.clear
          wind.write(":#{command}")
        end
      else
        # Cas d'une touche normale
        if start_command && s.is_a?(String)
          command << s
        end
        wind.write(s.to_s)
      end
    end
  end #/ interact_with_user

  T195_TO_LETTER = {
    168 => "è".freeze, 169 => "é".freeze, 170 => "ê".freeze, 171 => "ë".freeze,
    136 => 'È'.freeze, 137 => "É".freeze, 138 => 'Ê'.freeze, 139 => 'Ë'.freeze,
    167 => 'ç'.freeze, 135 => 'Ç'.freeze,
    160 => 'à'.freeze, 162 => 'ä'.freeze,
    128 => 'À'.freeze, 130 => 'Ä'.freeze,
    174 => 'î'.freeze, 175 => 'ï'.freeze,
    142 => 'Î'.freeze, 143 => 'Ï'.freeze,
    185 => 'ù'.freeze, 187 => 'û'.freeze, 188 => 'ü'.freeze,
    153 => 'Ù'.freeze, 155 => 'Û'.freeze, 156 => 'Ü'.freeze,
  }
  T194_TO_LETTER = {
    160 => ISPACE, #insécable
    171 => '«'.freeze, 187 => '»'.freeze
  }
  T226_TO_LETTER = {
    '128-148' => '—',
    '128-147' => '–',
    '128-156' => '“',
    '128-157' => '”',
  }
  def gestion_touches_speciales(s)
    curse = CWindow.uiWind.curse # raccourci
    s2 = curse.getch
    case s
    when 194
      T194_TO_LETTER[s2] || " --- inconnu avec 194  : #{s2}".freeze
    when 195
      T195_TO_LETTER[s2] || " --- inconnu avec 195 : #{s2}".freeze
    when 226
      suite = "#{s2}-#{curse.getch}".freeze
      T226_TO_LETTRE[suite] || " --- suite inconnue avec 226 : #{suite.inspect}".freeze
    end
  end #/ gestion_touches_speciales

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
