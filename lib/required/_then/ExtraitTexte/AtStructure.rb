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
  attr_reader :at, :from, :to, :nombre, :list, :at_init, :last, :first
  attr_reader :range # juste pour les message
  def initialize(at_init)
    @at_init = at_init.to_s # quelquefois, on envoie un nombre (annulation)
    parse
  end #/ initialize

  # Analyse le 'at' fourni pour l'index.
  #
  # Noter que dans tous les cas @list est défini et contient les
  # éléments voulus, que ce soit pour un index seul, une liste d'index
  # ou un range d'index.
  #
  # [1] On peut passer par ici, lorsque l'utilisateur a donné
  #     une "fausse" liste, par exemple "12,12"
  #
  def parse

    # Traitement du cas particulier d'une liste
    if at_init.match?(VG)
      traite_as_liste
    end

    if at_init.match?(TIRET) # => un rang
      @from, @to = at_init.split(TIRET).collect do |i|
        conforme?(i)
        i.to_i
      end
      @last = @to
      @first = @from
      @at = @from # par exemple pour replace
      @nombre = @to - @from + 1
      @is_a_range = true
      @list = (@from..@to).to_a
      @range = "#{@from}-#{@to}".freeze # attention : juste un string
    elsif list?
      @from = @first = list.first
      @to   = @tlast = list.last
      @nombre = list.count
    elsif !list? # [1]
      conforme?(at_init)
      @at = at_init.to_i
      @last = @first = @from = @to = @at
      @list = [@at] # pour simplifier certaines méthodes
    end
  end #/ parse

  # @Return la valeur absolue de +what+ (ou les valeur si
  # c'est une liste)
  # Par exemples
  #   ATStructure#absolute(:from) # => premier index absolu
  #   AtStructure#abs(:list)      # => liste des index absolu
  #
  # @alias def abs
  def absolute(what)
    case what
    when Integer
      what + iextrait_first_index
    when Symbol, String
      # log("what = #{what.inspect}")
      newwhat = send(what.to_sym)
      # log("newwhat = #{newwhat.inspect}")
      case newwhat
      when Integer
        newwhat + iextrait_first_index
      when Array
        newwhat.collect { |idx| abs(idx) }
      else
        raise "[1] Classe inconnue : #{newwhat.class}"
      end
    when Array
      what.collect { |idx| abs(idx) }
    else
      raise "[2] Classe inconnue : #{what.class}"
    end
  end #/ absolute
  alias :abs :absolute

  def iextrait_first_index
    @iextrait_first_index ||= Runner.iextrait.from_item
  end #/ iextrait_first_index

  def range?
    @is_a_range === true
  end #/ range?
  def list?
    @is_a_list === true
  end #/ list?

  # Liste Array des instances de text-items du At
  def titems
    @titems ||= begin
      list.collect { |idx| Runner.iextrait.extrait_titems[idx] }
    end
  end #/ titems

  # Premier text-item
  def first_titem
    @first_titem ||= titems.first
  end #/ first_titem

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

  # Retourne le contenu couvert par cette structure-at
  def content
    list.collect { |idx| Runner.iextrait.extrait_titems[idx].content }.join(EMPTY_STRING)
  end #/ content

private

  # On traite la donnée fournie comme une liste, de façon séparée, car
  # on peut réaliser que ce n'est pas vraiment une liste.
  def traite_as_liste
    # On découpe d'abord pour prendre chaque élément
    @list = at_init.split(VG).collect do |i|
      conforme?(i)
      i.strip.to_i
    end

    # On met toujours la liste dans l'ordre et avec des valeurs uniques
    @list = @list.uniq.sort

    # Si la liste n'a plus qu'une valeur, ce n'est pas une liste
    if @list.count == 1
      @at_init = @list.first
      @list = nil
      return
    end

    # On s'assure que ce soit une vraie liste discontinue (sinon,
    # c'est un range et on le traite comme tel)
    last_idx = nil
    @is_a_list = false # on part du principe qu'elle ne l'est pas
    @list.each do |idx|
      unless last_idx.nil?
        if idx != last_idx + 1
          # Si on trouve un seul élément qui n'est pas le suivi du
          # précédent, c'est que la liste n'est pas continue
          @is_a_list = true
          break
        end
      end
      last_idx = idx.dup
    end
    if false === @is_a_list
      # Si ce n'est pas vraiment une liste, on la transforme en range
      @at_init = "#{@list.first}-#{@list.last}"
      @range = @at_init.dup.freeze
      log("Les index fournis (#{@list.inspect}) ne sont pas une liste, c'est un rang (#{@at_init}). Je la traite comme telle.".freeze)
    end
  end #/ traite_as_liste

  # +i+ doit être un nombre correspondant à un index du texte
  def conforme?(i)
    raise(ERRORS[:entier_required] % i.inspect) unless i.integer?
    i = i.to_i
    raise[ERRORS[:index_positif] % [i]] if i < 0
    to_item = Runner.iextrait.to_item
    raise(ERRORS[:index_too_high] % [i, to_item]) if i > to_item # il doit être dans la fenêtre

    return true
  end #/ conforme?

ERRORS = {
  entier_required: "L'index %s devrait être un entier.".freeze,
  index_too_high: "L'index %i est trop grand (il doit être compris entre 0 et %i).".freeze,
  index_positif: "L'index doit être un nombre positif, de 0 à %i.".freeze
}
end
