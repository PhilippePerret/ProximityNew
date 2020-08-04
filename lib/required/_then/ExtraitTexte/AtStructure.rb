# encoding: UTF-8
=begin
  Class AtStructure
=end

# Transformer le params[:at] en ce qu'il est vraiment, en sachant qu'il peut
# être défini :
#   - par un chiffre seul     12
#   - par un range            12-14     de douze à quatorze
#   - par une liste           12,14,17    12, 14 et 17
#
# En sachant aussi que l'index donné est l'index relatif à la fenêtre
class AtStructure
  attr_reader :at, :from, :to, :nombre, :list, :at_init, :first_index
  def initialize(at_init, first_index)
    @at_init = at_init
    @first_index = first_index
    parse
  end #/ initialize

  # Analyse le 'at' fourni pour l'index.
  # 
  # Noter que dans tous les cas @list est défini et contient les
  # éléments voulus.
  def parse
    if at_init.match?(TIRET) # => un rang
      @from, @to = at_init.split(TIRET).collect{|i|i.to_i + first_index}
      @at = @from # par exemple pour replace
      @nombre = @to - @from + 1
      @is_a_range = true
      @list = (@from..@to).to_a
    elsif at_init.match?(VG)
      @list = at_init.split(VG).collect{|i|i.strip.to_i + first_index}
      @is_a_list = true
    else
      @at = at_init.to_i + first_index
      @list = [@at] # pour simplifier certaines méthodes
    end
  end #/ parse

  def range?
    @is_a_range === true
  end #/ range?
  def list?
    @is_a_list === true
  end #/ list?

  # Retourne le at en version humaine
  def to_s
    if range?
      "de #{from} à #{to} (#{nombre})".freeze
    elsif list?
      "pour les index #{list.join(VGE)}".freeze
    else
      "pour l’index #{at}".freeze
    end
  end #/ to_s

end
