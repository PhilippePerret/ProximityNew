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

if __FILE__ == $0
  require 'minitest/autorun'
  describe "Hash extension" do
    it "répond à la méthode to_sym" do
      hash = {}
      assert_respond_to hash, :to_sym
    end
    it "la méthode :to_sym met des clés symboliques" do
      hash = {'pour' => 'voir', 'et' => 'encore'}
      assert_equal hash.to_sym, {et: 'encore', pour: 'voir'}
    end
    it "la méthode :to_sym répond à l'argument deep" do
      hash = {'pour' => {'voir' => 'en'}, 'profondeur' => 'du hash'}
      refute_equal hash.to_sym(false), {pour: {voir: 'en'}, profondeur: 'du hash'}
      assert_equal hash.to_sym(false), {pour: {'voir' => 'en'}, profondeur: 'du hash'}
      assert_equal hash.to_sym(true), {pour: {voir: 'en'}, profondeur: 'du hash'}
    end
  end
end
