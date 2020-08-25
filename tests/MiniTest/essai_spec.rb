# encoding: UTF-8
=begin
  Note : je n'ai pas chargé RSpec et pourtant on peut faire les tests avec
  RSpec ici (peut-être seulement dans Atom) comme c'est le cas ci-dessous
  (c'est quand j'ai mis que le format du fichier était RSpec que ça a fonction-
  né)
=end

class Voeu
  def initialize
    @a = 12; @b = 21;
  end #/ initialize
  def add
    @a + @b
  end #/ add
end #/Voeu

describe "un essai" do
  it "doit être égal" do
    essai = Voeu.new
    expect(essai.add).to eq 33
  end
end
