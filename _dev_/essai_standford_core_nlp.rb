require 'stanford-core-nlp'

StanfordCoreNLP.use :french
StanfordCoreNLP.model_files = {}
# StanfordCoreNLP.set_model('pos.model', 'french.tagger')
StanfordCoreNLP.set_model('pos.model', 'stanford-corenlp-4.1.0-models-french.jar')
StanfordCoreNLP.default_jars = [
  'joda-time.jar',
  'xom.jar',
  'stanford-corenlp-3.5.0.jar',
  'stanford-corenlp-3.5.0-models.jar',
  'jollyday.jar',
  'bridge.jar'
]


texte = "Ceci est un texte assez cours sans redondance mais avec quelques redondances quand même parfois."


pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
text = StanfordCoreNLP::Annotation.new(texte)
pipeline.annotate(text)

text.get(:sentences).each do |sentence|
  puts sentence.get(:basic_dependencies).to_s
end
