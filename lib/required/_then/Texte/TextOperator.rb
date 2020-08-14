# encoding: UTF-8
class TextOperator
COL_OPE_WIDTH         = 10
COL_AT_WIDTH          = 16
COL_FILE_ID_WIDTH     = 6
COL_INDICE_MOT_WIDTH  = 10
class << self

end # /<< self
# ---------------------------------------------------------------------
#
#   INSTANCE
#
# ---------------------------------------------------------------------
attr_reader :itexte
def initialize(itexte)
  @itexte = itexte
end #/ initialize

def add_text_operation(params)
  init_operations_file if not File.exists?(path)
  operation = TextOperations.new(params.merge!(itexte:itexte))
  File.open(path,'a') do |f|
    f.puts(operation.as_code)
  end
end #/ add_text_operation

# Si le fichier des opérations n'existe pas encore, il faut l'initier
# Cela consiste principalement à indiquer la relation entre le file_id et
# le nom du dossier du fichier et le libellé des colonnes
def init_operations_file
  File.open(path,'a') do |f|
    if itexte.projet_scrivener?
      # Correspondance entre le file_id et le path
      f.puts "file_id        UUID du Binder"
      f.puts "-"*80
      ScrivFile.each do |scrivfile|
        f.puts "#{scrivfile.id.to_s.ljust(4)}#{scrivfile.uuid}"
      end
      f.puts RC*2
    end
    f.puts header
  end
end #/ init_operations_file

def header
  h = "#{SPACE.ljust(COL_OPE_WIDTH)}#{'Index'.ljust(COL_AT_WIDTH)}#{'File'.ljust(COL_FILE_ID_WIDTH)}#{'Indice'.ljust(COL_INDICE_MOT_WIDTH)}                   #{RC}"
  header_len = h.length
  h << "#{'Opération'.ljust(COL_OPE_WIDTH)}#{'absolu'.ljust(COL_AT_WIDTH)}#{'ID'.ljust(COL_FILE_ID_WIDTH)}#{'in file'.ljust(COL_INDICE_MOT_WIDTH)}Modification"
  h << (RC + TIRET*header_len).freeze

  h
end #/ header

# Raccourci au path du fichier contenant les opérations dans le dossier prox
# du texte.
def path
  @path ||= itexte.operations_file_path
end #/ path
end #/TextOperator

class TextOperations
  attr_reader :real_at, :content, :operation
  # Ajouté par TextOperator
  attr_reader :itexte, :titem_ref
  def initialize(params)
    params.each { |k,v| instance_variable_set("@#{k}", v)}
  end #/ initialize

  # Retourne l'opération comme code, pour l'enregistrer dans le fichier
  def as_code
    "#{operation.upcase.ljust(TextOperator::COL_OPE_WIDTH)}#{"#{real_at.range||real_at.list.join(VG)} ".ljust(TextOperator::COL_AT_WIDTH)}#{titem_ref.file_id.inspect.ljust(TextOperator::COL_FILE_ID_WIDTH)}#{titem_ref.indice_in_file.to_s.ljust(TextOperator::COL_INDICE_MOT_WIDTH)}#{modification}"
  end #/ as_code

  def modification
    case operation
    when 'insert'
      "<<< #{content} >>> #{real_at.content}"
    when 'remove'
      "-#{real_at.content}"
    when 'replace'
      "#{real_at.content} <<< #{content}"
    else
      "-- modification inconnue --"
    end
  end #/ modification
end #/TextOperations
