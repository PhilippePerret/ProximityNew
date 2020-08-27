# encoding: UTF-8
require './lib/required/_first/constants/String_constants.rb'

describe 'Constantes String' do
  it 'APO retourne une apostrophe' do
    expect(APO).to eq "'"
  end
  it 'LEMMA_UNKNOWN retourne <unknown>' do
    expect(LEMMA_UNKNOWN).to eq '<unknown>'
  end
end
