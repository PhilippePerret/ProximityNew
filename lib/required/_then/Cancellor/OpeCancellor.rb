# encoding: UTF-8
=begin
  Classe OpeCancellor
  -------------------
  Pour gérer une opération (une commande)
=end
class OpeCancellor
# ---------------------------------------------------------------------
#
#   CLASSE
#
# ---------------------------------------------------------------------
class << self

  # Récupère une donnée cancellisation enregistrée et retourne
  # son instance.
  def dejson(str)
    datacancel = JSON.parse(str).to_sym
    datacancel[:micro_operations] = datacancel[:micro_operations].collect{|mo|mo.to_sym}
    new(datacancel.delete(:command), datacancel.to_sym)
  end #/ dejson
end
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------

  attr_reader :command, :micro_operations
  def initialize(command, data = {})
    @command = command
    @time = data[:time] || Time.now.to_i
    @micro_operations = data[:micro_operations] || []
  end #/ initialize

  def add_operation(ope_data)
    @micro_operations.unshift(ope_data)
  end #/ add_operation
  alias :<< :add_operation

  def to_json
    {
      command: @command,
      micro_operations: micro_operations,
      time: @time
    }.to_json
  end #/ to_json

  # Pour annuler l'opération
  def undo
    micro_operations.each do |params|
      operation = params.delete(:operation)
      params.merge!(real_at: AtStructure.new(params.delete(:index), 0))
      Runner.iextrait.send(operation, params)
    end
  end #/ undo

end #/OpeCancellor
