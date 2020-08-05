# encoding: UTF-8
=begin
  Chargement des bibliothèques requises pour les tests
=end

TEST_LIB_FOLDER = File.dirname(__FILE__)
TESTS_FOLDER    = File.dirname(TEST_LIB_FOLDER)
TEST_APP_FOLDER = File.dirname(TESTS_FOLDER)

Dir["#{TEST_LIB_FOLDER}/required/_first/**/*.rb"].each{|m|require(m)}
Dir["#{TEST_LIB_FOLDER}/required/_then/**/*.rb"].each{|m|require(m)}

include MainTestModule # Pour toutes les méthodes fake (run, expect_ui, etc.)

# Indiquer qu'on est ne mode test
ENV['MODE_TEST'] = 'true'

# Requérir toutes les librairies de l'application
require File.join(TEST_APP_FOLDER,'lib','required')

# Requérir toutes les librairies qui écrasent les librairies
# d'origine, au niveau de l'affichage principalement.
Dir["#{TEST_LIB_FOLDER}/required/_mocks/**/*.rb"].each{|m|require(m)}

CWindow.init_curses
