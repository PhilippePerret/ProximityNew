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

CMD_TEMPLATE = <<-CODE.freeze
#{BINARY_PATH} <<EOT
%s
EOT
CODE

class << self

  # Parse +itexte+ qui peut être une instance Texte ou un simple Path
  def parse(itexte)
    File.delete(lemma_error_path) if File.exists?(lemma_error_path)
    cmd = ("#{BINARY_PATH}" +
           " < #{itexte.only_mots_path.inspect}" +
           " > #{itexte.lemma_data_path.inspect}"+
           " 2> #{lemma_error_path}").freeze
    log("cmd lemmatisation : #{cmd}".freeze)
    lemma_result = `#{cmd}`
    # if File.exists?(lemma_error_path)
    #   NON, PAS FORCÉMENT
    #   erreur("Une erreur TreeTager est survenue, consulter le fichier error_lemma.log.")
    # end

    lemma_result
  end #/ parse

  def parse_str(str, options = nil)
    options ||= {}
    options[:system] ||= true # pour utiliser Open3.popen3
    options.merge!(format: :raw) unless options.key?(:format)
    res = nil
    if options[:system]
      require 'open3'
      log("parse_str par le système")
      # TODO Voir encore Process, spawn pour voir si je pourrais faire
      # quelque chose…
      # L'avantage de Open3.popen3 ci-dessous, c'est qu'il n'y a plus rien
      # qui passe en console, plus de messages envoyés par TreeTagger.
      Open3.popen3(BINARY_PATH) do |stdin, stdout, stderr, thread|
         pid = thread.pid
         stdin.puts str
         stdin.close
         # log(stdout.read.chomp, true)
         res = stdout.read.chomp
      end
    else
      CMD_TEMPLATE % str
      res = `#{cmd}`
    end
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


  def lemma_error_path
    @lemma_error_path ||= File.join(APP_FOLDER,'error_lemma.log')
  end #/ lemma_error_path

end # /<< self

end #/Lemma
