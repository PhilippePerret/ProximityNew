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
    str = "#{Time.now.to_s}-- #{str}" if options[:time]
    File.open(path,'a'){|f|f.write(str.freeze + RC)}
  end #/ add

  def path
    @path ||= File.join(APP_FOLDER,'debug.log')
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
    @path ||= File.join(APP_FOLDER,'error.log')
  end #/ path
end # /<< self
end #/Errorer

class Log
class << self
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
    File.delete(logpath) if File.exists?(logpath)
    File.open(logpath,'a')
  end
end #/ reflog
def logpath
  @logpath ||= File.join(APP_FOLDER,'journal.log')
end #/ logpath
end #/Log
