# encoding: UTF-8
class Lemma
NATURE_TO_SYMBOL = {
  'VER' => :verbe, 'DET' => :determinant, 'ADJ' => :adjectif, 'NOM' => :nom,
  'PRO' => :pronom, 'PRO:PER' => :pronom_personnel,
  'PRP' => :preposition, 'SENT' => :point, 'KON' => :kon,
  'ADV' => :adverbe,
  'NUM' => :nombre,
  'NAM' => :prenom,
  'ABR' => :abbreviation, # km => kilomètre
}
class << self

  # Parse +itexte+ qui peut être une instance Texte ou un simple Path
  def parse(itexte)
    path = itexte.is_a?(String) ? itexte : itexte.path
    dst_path = "#{path}_lemma.data".freeze
    cmd = "/usr/local/bin/tree-tagger-french < \"#{path}\" > \"#{dst_path}\""
    `#{cmd}`
    return dst_path
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
