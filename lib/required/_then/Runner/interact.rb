# encoding: UTF-8
=begin
  Partie interactive du Runner
=end

# Quand la clé est détectée dans la commande, le clavier passe dans le
# mode défini. Par exemple, quand on tape "ins ", l'interacteur passe en
# mode "chiffres_simples" qui permet d'écrire les chiffres avec les touches
# de Q à M (de 0 à 9)
# Cette fonctionnalité peut se désactiver dans les préférences de l'application
COMMANDS_TO_MODE = {
  'del '  => {mode: :chiffres_simples},
  'ign '  => {mode: :chiffres_simples},
  'ins '  => {mode: :chiffres_simples},
  'inj '  => {mode: :chiffres_simples},
  'rep '  => {mode: :chiffres_simples},
  'dep '  => {mode: :chiffres_simples},
  'mov '  => {mode: :chiffres_simples},
  'rem '  => {mode: :chiffres_simples},
  'show ' => {mode: :chiffres_simples},
  'sup '  => {mode: :chiffres_simples},
}

MODES_CLAVIER = {
  chiffres_simples: {
    dim: ['NUMBER', CWindow::BLUE_COLOR], # pour l'affichage dans la fenêtre de statut
    exclusif: true, # aucune autre touche que celles définies ci-dessous
    fin: /[0-9]+ $/, # on sort de ce mode quand on obtient ça pour la commande
    'q'=>'1', 's'=>'2', 'd'=>'3', 'f'=>'4', 'g'=>'5', 'h'=>'6', 'j'=>'7', 'k'=>'8', 'l'=>'9', 'm'=>'0',
    ' ' => ' ', TIRET=>TIRET,
    # Puisque le mode est exclusif, il faut indiquer toutes les touches qui
    # doivent pouvoir passer.
    27=>27, 127=>127, 10=>10,
  }
}

module Runner
class << self

# Pour revenir au mode de clavier normal
def reset_mode_clavier
  @mode_clavier = nil
  CWindow.init_status_and_cursor
end #/ reset_mode_clavier

def interact_with_user
  wind  = CWindow.uiWind
  wind.write("Taper “:help” pour obtenir de l’aide. Pour quitter : “:q”")
  curse = wind.curse # raccourci
  start_command = false # mis à true quand il tape ':'
  command = nil
  reset_mode_clavier
  while true
    # On attend sur la touche de l'utilisateur
    unless @mode_clavier.nil?
      if @mode_clavier[:fin] && command.match?(@mode_clavier[:fin])
        reset_mode_clavier
      end
    end
    s = curse.getch
    unless @mode_clavier.nil?
      s = @mode_clavier[s]
      case s
      when NilClass
        next if @mode_clavier[:exclusif]
      when :end, :fin
        reset_mode_clavier
        next
      end
    end
    case s
    when 10 # Touche retour => soumission de la commande
      log("Soumission de la commande #{command.inspect}")
      case command
      when 'q'
        Runner.finish
        break # C'est la fin
      else
        reset_mode_clavier
        wind.clear
        begin
          Commande.run(command)
        rescue Exception => e
          log("ERROR COMMANDE : #{e.message}#{RC}#{e.backtrace.join(RC)}")
          CWindow.error("Une erreur fatale est survenue (#{e.message}). Quitter et consulter le journal de bord.")
        end
      end
    when 194, 195, 226 # pour les accents et diacritiques
      s3 = gestion_touches_speciales(s)
      if start_command
        command << s3
        wind.clear
        wind.write(":#{command}")
      end
    when 27 # Escape button
      if @mode_clavier.nil?
        start_command = false
        command = ""
        wind.clear
        wind.write(EMPTY_STRING)
      else
        reset_mode_clavier
      end
    when ':'
      start_command = true
      command = ""
      wind.resetpos
      wind.write(':')
    when 261 # RIGHT ARROW
      Commande.run('next page')
    when 260 # LEFT ARROW
      Commande.run('prev page')
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
    # Faut-il passer dans un mode clavier particulier ?
    if start_command && COMMANDS_TO_MODE[command]
      @mode_clavier = MODES_CLAVIER[COMMANDS_TO_MODE[command][:mode]]
      CWindow.init_status_and_cursor(@mode_clavier[:dim])
    end
  end #/ tanq que rien ne sort
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

end #/<< self
end #/Runner
