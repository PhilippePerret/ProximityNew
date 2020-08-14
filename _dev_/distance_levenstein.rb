require "levenshtein"

DISTANCE_MINIMALE = 20

# DamerauLevenshtein.distance("Something", "Smoething") #returns 1

FILE_PATH = "/Users/philippeperret/Downloads/Spe1.txt"

# phrases = []
# File.foreach(FILE_PATH) do |line|
#   phrases << line
# end


# p phrases.inspect
phrases = File.read(FILE_PATH).force_encoding("ISO-8859-5").encode("UTF-8").split(/.Pour /).collect{|p| "Pour #{p}"}

# Quand il n'y aura plus de problème d'encodage :
# phrases = []
# File.foreach(FILE_PATH) do |line|
#   phrases << line.force_encoding("ISO-8859-5").encode("UTF-8")
# end

nombre_phrases = phrases.count
puts "Nombre de phrases : #{nombre_phrases}"

DST_FILE = "/Users/philippeperret/Downloads/Spe1-levenshtein.txt"
File.delete(DST_FILE) if File.exists?(DST_FILE)
reffile = File.open(DST_FILE,'a')
begin

  phrases.each_with_index do |phrase1, idx|
    @source_ok = false
    (idx+1..nombre_phrases-1).each do |idx2|
      phrase2 = phrases[idx2]
      distance = Levenshtein.distance(phrase1, phrase2)
      if distance < DISTANCE_MINIMALE
        unless @source_ok
          reffile.puts "\r\n\r\nSOURCE : [#{idx}] #{phrase1}"
          @source_ok = true
        end
        # puts phrase1.inspect
        # puts phrase2.inspect
        # puts distance
        # sleep 0.5
        reffile.puts "-- Dist. #{distance} : [#{idx2}] #{phrase2}"

        # break
      end

    end

    # break if @source_ok #pour l'essai

  end

ensure
  reffile.close
end
