# encoding: UTF-8
=begin
  Module de test de ConfigModule.rb
=end
require './lib/required/_first/ConfigModule.rb'
# Pour pouvoir tester le module config
# on doit créer une classe quelconque
class Dummy
  include ConfigModule
  def config_path
    @config_path ||= "./tmp/tests/configmodule.json".tap {|p| `mkdir -p "#{File.dirname(p)}"`}
  end #/ config_path
  def config_default_data
    @config_default_data ||= {pour: "voir", et: "pour sentir"}
  end #/ config_default_data
end

describe Dummy do
  it { is_expected.to respond_to :config }
  it { is_expected.not_to respond_to :bloubiboulga }
  # Pour définir le fichier configuration
  it { is_expected.to respond_to :config_path }
  it { is_expected.to respond_to :config_default_data }
end

describe Dummy::ConfigFile do
  subject { Dummy::ConfigFile.new(Dummy.new) }
  it { is_expected.to respond_to :[] }
  it { is_expected.to respond_to :load }
  it { is_expected.to respond_to :data }
  it { is_expected.to respond_to :path }
  it 'la méthode :[] permet de récupérer une valeur de config' do
    expect(subject[:pour]).to eq "voir"
    expect(subject[:et]).to eq "pour sentir"
  end
  it 'la méthode :save permet de définir une valeur' do
    subject.save(nouvelle: "valeur")
    newdata = JSON.parse(File.read(subject.path))
    expect(newdata['nouvelle']).to eq "valeur"
  end
end

describe Dummy.new.config do
  it { is_expected.to respond_to :[] }
  it '[] permet de récupérer une valeur de configuration' do
    expect(subject).to respond_to :[]
    expect(subject[:pour]).to eq "voir"
    expect(subject[:et]).to eq "pour sentir"
  end
  it 'save permet de sauver des valeurs de configuation' do
    expect(subject).to respond_to :save
    subject.save(new: "value")
    newdata = JSON.parse(File.read(subject.path))
    expect(newdata['new']).to eq "value"
  end
end
