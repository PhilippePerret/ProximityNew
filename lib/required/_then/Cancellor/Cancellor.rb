# encoding: UTF-8
=begin
  Classe Cancellor
  ----------------
  Pour gérer les annulations
=end
class Cancellor

attr_reader :itexte
def initialize(itexte)
  @itexte = itexte
end #/ initialize

def undo_last
  cancel = cancellations.pop
  unless cancel.nil?
    cancel.undo
    save
  end
end #/ undo_last

def ask_for_cancel_last
  unless cancellations.last.nil?
    msg = "Voulez-vous vraiment annuler la commande : #{cancellations.last.command} (o/y => oui, n => non)".freeze
    choix = CWindow.wait_for_user(message:msg, keys:['o','y','n'])
    undo_last if choix == 'o' || choix == 'y'
  else
    CWindow.log("Il n'y a pas de dernière opération à annuler.", RED_COLOR)
  end
end #/ ask_for_cancel_last

# Ajoute l'opération cancellisable et sauve les annulations possible
def add_and_save(ope_cancellor)
  cancellations << ope_cancellor
  cancellations.shift if cancellations.count > 20
  save
end #/ add

def save
  File.open(path,'wb') do |f|
    f.write(cancellations.collect{|c|c.to_json}.to_json)
  end
end #/ save

def load
  @cancellations = []
  if File.exists?(path)
    JSON.parse(File.read(path)).each do |opecancel|
      @cancellations << OpeCancellor.dejson(opecancel)
    end
  end
  @cancellations
end #/ load

def cancellations
  @cancellations || load
end #/ cancellations

def path
  @path ||= File.join(itexte.prox_folder, 'cancels.json')
end #/ path
end #/Cancellor
