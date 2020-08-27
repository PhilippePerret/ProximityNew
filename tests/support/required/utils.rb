# encoding: UTF-8
=begin
  Méthodes utiles
=end
def require_in(path)
  Dir[File.join(path,'**','*.rb')].each{|m|require(m)}
end #/ require_in
