# encoding: UTF-8

require './lib/required/_first/constants/proximites.rb'

def constante_existe &block
  expect { yield }.not_to raise_error
end #/ constante_existe

describe 'Constantes proximités' do
  # it 'la constante BLOUBIBOULGA n’exste pas' do
  #   constante_existe { BLOUBIBOULGA }
  #   # constante_existe(BLOUBIBOULGA)
  # end
  it 'la constante DISTANCE_MINIMALE_COMMUNE existe' do
    constante_existe { DISTANCE_MINIMALE_COMMUNE }
  end
  it 'la constante MOTS_SANS_PROXIMITES existe' do
    constante_existe { MOTS_SANS_PROXIMITES }
  end
  it 'la constante MOTS_APOSTROPHE existe' do
    constante_existe { MOTS_APOSTROPHE }
  end
  it 'la constante MOTS_TIRET existe' do
    constante_existe { MOTS_TIRET }
  end
  it 'la constante TRANSFORMABLES existe' do
    constante_existe { TRANSFORMABLES }
  end
  it 'la constante LOCUTIONS existe' do
    constante_existe { LOCUTIONS }
  end

end
