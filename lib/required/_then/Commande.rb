# encoding: UTF-8
class Commande
class << self
  def run(cmd)
    cmd = cmd.split(SPACE)
    cmd_name = cmd.shift
    case cmd_name
    when 'ins', 'insert'
      where = cmd.shift
      where_index = cmd.shift
      texte = cmd.join(SPACE)
      log("Insérer le texte “#{texte}”")
    end
  end #/ run


  def log(str)
    CWindow.logWind.write(str)
  end #/ log
end # /<< self
end #/Commande
