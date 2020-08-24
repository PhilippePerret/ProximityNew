# encoding: UTF-8
=begin
  Extension de Texte
=end
class Texte
  # Méthode d'affichage principale qui indique le nombre d'occurence du
  # mot +mot+ dans le texte.
  # @Params
  #   +mot+   {String|Mot}  Le mot dont il faut connaitre les occurences
  def show_occurences_of(mot)
    occur = StructOccurence.new(mot, self)
    # On affiche le résultat
    log(occur.output(:console), true)
  end #/ show_occurences_of

end #/Texte

class StructOccurence
  attr_reader :itexte # instance du Texte contenant le mot
  attr_reader :mot_init # String ou Mot
  def initialize(mot, itexte)
    @mot_init = mot
    @itexte   = itexte
  end #/ initialize

  def output(type)
    case type
    when :console
      output_console
    end
  end #/ output

  # Sortie pour la console
  def output_console
    msg = ["Mot “#{mot}”"]
    msg << "#{occurences_mot} occurence#{occurences_mot > 1 ? 's' : ''} du mot exact"
    if canon == '<unknown>'
      msg << "canon inconnu"
    elsif occurences_canon == 0
      msg << "aucune occurence du canon “#{canon}”"
    else
      msg << "#{occurences_canon} occurence#{occurences_canon > 1 ? 's' : ''} du canon “#{canon}”"
    end
    msg.join(SPACE+BARV+SPACE)
  end #/ output_console

  def occurences_mot
    @occurences_mot ||= itexte.db.occurences_of_mot(mot)
  end #/ occurences_mot

  def occurences_canon
    @occurences_canon ||= begin
      if canon == '<unknown>'
        0
      else
        itexte.db.occurences_of_canon(canon)
      end
    end
  end #/ occurences_canon
  def mot
    @mot ||= (text_item? ? mot_init.content : mot_init)
  end #/ mot
  def canon
    @canon ||= begin
      if text_item?
        mot_init.canon
      else
        can = Runner.db.get_canon(mot_init)
        can ||= Lemma.parse_str(mot_init, format: :array)[0][2].split(BARV).first
      end
    end
  end #/ canon
  def text_item?
    @is_text_item ||= mot_init.is_a?(Mot) ? :true : :false
    @is_text_item == :true
  end #/ text_item?
end #/ StructOccurence
