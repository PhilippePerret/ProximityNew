#!/usr/bin/env ruby -Ku

Dir["./lib/required/_then/Scrivener/**/*.rb"].each{|m|require(m)}

include ScrivenerModule

@projet = Scrivener::Projet.new("/Users/philippeperret/Documents/Ecriture/Romans/Le_Parc/Le_Parc-copie.scriv/Le_Parc.scrivx")


# puts projet.docxml.root.elements["Binder/BinderItem"][0]

# Récupération de tous les fichiers texte du roman
@projet.get_all_files

# Ce qu'il faut faire ensuite pour récupérer le texte :
#  1- récupérer l'entête de chaque fichier et le placer dans la base de
#     données (ou alors créer un fichier entête — header.txt)
#  2- Récupérer le texte en le mettant en txt grâce à textutil
#
# Pour repasser en RTF
#  1- Utiliser TextUtil à l'envers
#  2- Transformer les balises style <::0> vers <$Scr_Cs::0> et <!::0> vers <!$Scr_Cs::0>
#     car bizarrement, de txt->rtf les balises gardées <$Scr_Cs::0>.
#     TODO Peut-être essayer de les "protéger"
#  3- Remettre l'entête originale
#


puts @projet.files.join("\n")

# puts `pandoc #{@projet.files.first} -f rtf -t txt`
# puts `textutil -format rtf -convert txt -stdout "#{rtf_text_path}"`

def traite_file(fpath)

  puts "\n\n\n-- Traitement de : #{fpath}"
  puts "\n\n--- Fichier transformé en TXT ---"
  res = `textutil -format rtf -convert txt -stdout "#{fpath}"`
  puts res
  puts "\n\n\n--- Fichier TXT transformé en RTF ---"
  cmd = <<-CODE
textutil -format txt -convert rtf -stdout -stdin <<EOT
#{res}
EOT
  CODE
  res = `#{cmd}`
  puts res

end #/ traite_file

puts "\n\nRecherche du fichier…"
@projet.files.each do |fpath|
  dossier = File.basename(File.dirname(fpath))
  if dossier.start_with?('0BA8A33D')
    traite_file(fpath)
  end
end
exit
