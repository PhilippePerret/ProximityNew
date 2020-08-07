# encoding: UTF-8
class Hash

  def to_sym(deep = false)
    hfin = {}
    self.each do |k, v|
      if deep
        v = case v
        when Hash
          v.to_sym
        else
          v
        end
      end
      hfin.merge!(k.to_sym => v)
    end
    return hfin
  end #/ to_sym

end #/Hash
