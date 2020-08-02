# encoding: UTF-8
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


def log(str)
  Log.log(str)
end #/ log
