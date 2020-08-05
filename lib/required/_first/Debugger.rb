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
