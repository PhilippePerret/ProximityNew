# encoding: UTF-8
=begin
  Pour surclasser les méthodes de CWindow
=end

class CWindow
class << self
  def log(msg)
    puts "CWindow.log a reçu #{msg.inspect}"
  end #/ log
  def status(msg)
    puts "CWindow.status a reçu #{msg.inspect}"
  end #/ status
  def textWind
    @textWind ||= CWindowForTest.new('textWind')
  end #/ textWind
  def uiWind
    @uiWind ||= CWindowForTest.new('uiWind')
  end #/ uiWind
end # /<< self
end #/CWindow
