# encoding: UTF-8
=begin
  Essai de test
=end
# On joue une commande
CLAVIER = ['q']
class Help
  def self.on_quit; return true end
end
run_commande(':help')
ecran.contient('=== AIDE DU PROGRAMME PROXIMITÉS ===')

# # *** contrôle du contenu des fenêtre ***
# expect(CWindow.textWind).to contain("AIDE DU PROGRAMME PROXIMITÉS")
# expect_ui(le_texte_dans_uiWind)
# expect_log(le_texte_dans_logWind)
# expect_status(le_texte_dans_statusWind)
# # *** contrôle des données ***
# expect(itexte).to have_item(item_voulu)
# expect(textitem).to have_properties(properties_voulues)
# expect(Canon).to have_canon(canon_voulu)
# # *** Contrôle d'un projet Scrivener ***
