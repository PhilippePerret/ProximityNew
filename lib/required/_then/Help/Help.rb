# encoding: UTF-8
=begin
  Module pour l'aide

  L'aide a son propre attente interactive.
=end
class Help
class << self
  attr_accessor :first_line, :last_line
  # Destinataire de l'aide, l'utilisateur ou le développeur
  attr_accessor :destinataire


  def show(suite_cmd)
    options = {destinataire: :user}
    first_arg = suite_cmd.shift
    case first_arg
    when 'dev', 'developper', 'development', 'developpement'
      options[:destinataire] = :developper
    end
    # On ajoute les lignes pour savoir où on se trouve
    options.merge!(first_line: 0) unless options.key?(:first_line)
    options.merge!(last_line: CWindow.hauteur_texte) unless options.key?(:last_line)
    self.first_line = options[:first_line]
    self.last_line  = options[:last_line]
    CWindow.log("Affichage de l'aide (ligne #{first_line} à #{last_line}).")
    CWindow.textWind.clear
    CWindow.textWind.write(aide_lines[first_line..last_line].join(RC), CWindow::WHITE_ON_BLACK)
    interact_with_user
  end #/ show

  def aide_lines
    @aide_lines ||= if destinataire == :user
      AIDE_USER_STRING.split(RC)
    else
      AIDE_DEVELOPPER_STRING.split(RC)
    end
  end #/ aide_lines
  def nombre_lignes_aide
    @nombre_lignes_aide ||= aide_lines.count
  end #/ nombre_lignes_aide

  def interact_with_user
    wind  = CWindow.uiWind
    curse = wind.curse # raccourci
    start_search = false
    while true
      s = curse.getch
      case s
      when 'q'
        on_quit
        break
      when '/'
        start_search = true
        search = ""
      when 258 # flèche bas => descendre
        if last_line + 1 < nombre_lignes_aide
          show(first_line: first_line + 1, last_line: last_line + 1)
        end
      when 259 # flèche haut => remonter
        if first_line > 0
          show(first_line: first_line - 1, last_line: last_line - 1)
        end
      when 27 # Escape button
        start_search = false
        search = ""
        wind.clear
        wind.write(EMPTY_STRING)
      when 127 # effacement arrière
        if start_search
          search = search[0...-1]
          wind.clear
          wind.write("/#{search}")
        end
      else
        if start_search && s.is_a?(String)
          search << s
        end
        wind.write(s.to_s)
      end
    end
  end #/ interact_with_user

  def on_quit
    Runner.iextrait&.output
  end #/ on_quit

end # /<< self

end #/Help
