module MainTestModule
  def run_commande(commande)
    commande = commande[1..-1] if commande[0] == ':'
    puts "Je joue '#{commande}'"
    Commande.run(commande)
  end #/ run

  def use_texte(tpath)
    Runner.open_texte(tpath)
    # Runner.instance_variable_set('@itexte', Texte.new(tpath))
  end #/ use_texte

  def ecran
    @ecran ||= CWindow.textWind
  end #/ ecran
end
