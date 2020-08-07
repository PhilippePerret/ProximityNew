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

def log(str, window_too = false)
  Log.log(str)
  CWindow.log(str) if window_too
end #/ log

def erreur(err)
  if err.respond_to?(:message)
    err_mess = "#{err.message} (quitter et consulter le journal.log)"
    err_log = "ERROR: #{err.message}#{RC}#{err.backtrace.join(RC)}"
  else
    err_mess = err_log = err
  end
  CWindow.error(err_mess)
  Log.log(err_log)
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
  def log(str)
    reflog.write(Time.now.to_s+SPACE+str+RC)
  end #/ log
  def reflog
    @reflog ||= begin
      File.delete(logpath) if File.exists?(logpath)
      File.open(logpath,'a')
    end
  end #/ reflog
  def logpath
    @logpath ||= File.join(APP_FOLDER,'journal.log')
  end #/ logpath
end # /<< self
end #/Log
