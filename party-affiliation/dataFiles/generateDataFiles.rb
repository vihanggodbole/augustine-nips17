LINE_SEARCH_PATTERN = '__count__'
NAME_SEARCH_PATTERN = 'template'
TEMPLATE_PATH = File.join('.', "party-affiliation-#{NAME_SEARCH_PATTERN}.data")

REPLACE_VALUES = ['22050', '33075', '38588', '44100', '49613', '55125', '66150']

def main(args)
   REPLACE_VALUES.each{|value|
      File.open(TEMPLATE_PATH, 'r'){|inFile|
         File.open(TEMPLATE_PATH.sub(NAME_SEARCH_PATTERN, value), 'w'){|outFile|
            inFile.each{|line|
               outFile.puts(line.gsub(LINE_SEARCH_PATTERN, value))
            }
         }
      }
   }
end

if ($0 == __FILE__)
   main(ARGV)
end
