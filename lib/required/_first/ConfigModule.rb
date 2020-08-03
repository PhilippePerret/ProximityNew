# encoding: UTF-8
=begin
  Pour inclure les méthodes de gestion du fichier de configuration

  La classe qui inclut ce module doit définir :

  config_path             Chemin d'accès au fichier de configuration
  config_default_data     Hash des données par défaut

=end
require 'json'
module ConfigModule
  def config
    @config ||= ConfigFile.new(self)
  end #/ config
  # Doit être écrasé par la classe appelante
  def config_default_data
    {}
  end #/ config_default_data
  class ConfigFile
    attr_reader :owner, :data
    def initialize(owner)
      @owner = owner
    end #/ initialize
    # ---------------------------------------------------------------------
    #   Méthodes publiques
    # ---------------------------------------------------------------------
    def [] key
      data[key]
    end #/
    def load
      if File.exists?(path)
        JSON.parse(File.read(path), symbolize_names:true)
      end
    end #/ load
    def save(hdata = nil)
      data.merge!(hdata) unless hdata.nil?
      data.merge!(last_saved: Time.now.to_i)
      File.open(path,'wb'){|f|f.write(data.to_json)}
    end #/ save
    # ---------------------------------------------------------------------
    #   Méthode d'I/O
    # ---------------------------------------------------------------------
    def data
      @data ||= load() || owner.config_default_data
    end #/ data
    def path
      @path ||= owner.config_path
    end #/ path
  end #/ConfigFile

end
