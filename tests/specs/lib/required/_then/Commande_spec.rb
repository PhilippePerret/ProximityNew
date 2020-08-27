# encoding: UTF-8
=begin
  Test du module Commande.rb, de la class Commande
  qui reçoit les commandes de l'user
=end
require './tests/support/required'
require './lib/required/_then/Commande.rb'

describe Commande do
  subject { Commande }
  it { is_expected.to respond_to :run }
  it { is_expected.not_to respond_to :bloubi }

  describe 'Commande.run' do
    it 'avec "next" toute seule produite une erreur' do
      Commande.run('next')
      expect(message_derreur).to eq "Je ne sais pas traiter le 'next' de ''."
    end
    it 'mémorise la commande' do
      Commande.run('open')
      expect(Commande.historique.last).to eq 'open'
    end
  end #/describe Commande.run
end
