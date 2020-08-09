# encoding: UTF-8
require 'treetagger'

class Lemma
BINARY_PATH = "/usr/local/bin/tree-tagger-french"
NATURE_TO_SYMBOL = {
  'VER' => :verbe, 'DET' => :determinant, 'ADJ' => :adjectif, 'NOM' => :nom,
  'PRO' => :pronom, 'PRO:PER' => :pronom_personnel,
  'PRP' => :preposition, 'SENT' => :point, 'KON' => :kon,
  'ADV' => :adverbe,
  'NUM' => :nombre,
  'NAM' => :prenom,
  'ABR' => :abbreviation, # km => kilomètre
}
END_MARKER = TreeTagger::Tagger::END_MARKER
END_SENTENCE = "Pour\nMarquer\nLa\nFin\n"

class << self

  # Parse +itexte+ qui peut être une instance Texte ou un simple Path
  def parse(itexte)
    cmd = ("#{BINARY_PATH}" +
           " < #{itexte.only_mots_path.inspect}" +
           " > #{itexte.lemma_data_path.inspect}").freeze
    log("cmd lemmatisation : #{cmd}".freeze)
    `#{cmd}`
  end #/ parse

  def parse_str(str, options = nil)
    options ||= {}
    options.merge!(format: :raw) unless options.key?(:format)
    cmd = <<-CODE
/usr/local/bin/tree-tagger-french <<TEXT
#{str}
TEXT
    CODE
    res = `#{cmd}`
    case options[:format]
    when :raw
      res
    when :array
      res.split(RC).collect do |line|
        line.split(TAB)
      end
    when :instances
      res.split(RC).collect do |line|
        TexteItem.lemma_to_instance(line)
      end
    end

  end #/ parse_str
end # /<< self

end #/Lemma
