# encoding: UTF-8
=begin
  Class Debugger
  --------------
  Pour débugger le programme
=end

=begin
  options Hash
    :time   Si true, on ajoute le temps (non mis par défaut)
=end
def debug(str, options = nil)
  Debugger.add(str, options)
end #/ debug

# Méthode pour débugger une liste de text-items
#
# @Params
#     @titems   Array   Liste des instances text-item (mots ou non-mots)
#     @options  Hash
#       :from   Depuis cet index (sinon 0)
#       :to     Jusqu'à cet index (sinon le dernier)
#       :titre  Titre à donner à la liste.
#
def debug_titems(titems, options = nil)
  options ||= {}
  options[:from]  ||= 0
  options[:to]    ||= titems.count -1
  delimitation = (RC*3 + TIRET*80 + RC*3).freeze
  log(delimitation)
  log(options[:titre]||"Débuggage d'une liste de text-items")
  temp = '%s%s%s%s'.freeze
  items.each do |titem|
    log(temp % [titem.content.ljust(20), (titem.index||'nil').to_s.ljust(8), (titem.offset||'nil').to_s.ljust(10), titem.canon.to_s.ljust(20)])
  end
  log(delimitation)
end #/ debug_titems

# Quand +str+ est nil, c'est un appel à l'instance, par exemple pour
# fermer l'accès au fichier journal.log avec `log.close`. Sinon c'est un
# appel "normal" avec écriture dans le fichier journal.
# Si +window_too+ est vrai, on écrit aussi le message dans le fenêtre
def log(str = nil, window_too = false)
  if str.nil?
    @logger ||= Log.current
  else
    Log.current.add(str)
    CWindow.log(str) if window_too
  end
end #/ log

def erreur(err)
  if err.respond_to?(:message)
    err_mess = "#{err.message} (quitter et consulter le journal.log)"
    err_log = "ERROR: #{err.message}#{RC}#{err.backtrace.join(RC)}"
  else
    err_mess = err_log = err
  end
  CWindow.error(err_mess)
  Log.current.add(err_log)
  Errorer.add(err_log)
end #/ error
alias :error :erreur


class Debugger
class << self

  def add(str, options = nil)
    options ||= {}
    str = str.to_s
    if options[:time]
      str = "#{Time.now.to_s}-- #{str}"
    end
    File.open(path,'a'){|f|f.write(str.freeze + RC)}
  end #/ add

  def path
    @path ||= File.join(APP_FOLDER,'logs','debug.log')
  end #/ path

end # /<< self
end #/Debugger

class Errorer
class << self

  def add(msg)
    str = "#{Time.now.to_s}-- #{msg}"
    File.open(path,'a'){|f|f.write(str.freeze + RC)}
  end #/ add
  alias :<< :add

  def path
    @path ||= File.join(APP_FOLDER,'logs','error.log')
  end #/ path
end # /<< self
end #/Errorer

class Log
class << self
  def init
    new().init
  end #/ init
  def current
    @current ||= new
  end #/ current
end # /<< self
def add(str)
  reflog.write(Time.now.to_s+SPACE+str+RC)
end #/ add
def close
  reflog.close
  @reflog = nil # pour le rouvrir
end #/ close
def reflog
  @reflog ||= begin
    File.open(logpath,'a')
  end
end #/ reflog
def init
  File.delete(logpath) if File.exists?(logpath)
end #/ init
def logpath
  @logpath ||= File.join(APP_FOLDER,'logs','journal.log')
end #/ logpath
end #/Log
