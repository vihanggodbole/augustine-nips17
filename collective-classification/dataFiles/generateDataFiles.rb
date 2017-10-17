NAME_SEARCH_PATTERN = 'template'
TEMPLATE_PATH = File.join('.', "collective-classification-#{NAME_SEARCH_PATTERN}.data")

FIRST_LINE_SEARCH_PATTERN = '__dataset__'
SECOND_LINE_SEARCH_PATTERN = '__fold__'
THIRD_LINE_SEARCH_PATTERN = '__type__'

FIRST_LINE_REPLACE_VALUES = ['citeseer', 'cora']
SECOND_LINE_REPLACE_VALUES = (0...20).to_a().map{|val| "%02d" % val}
THIRD_LINE_REPLACE_VALUES = ['learn', 'eval']

def main(args)
   FIRST_LINE_REPLACE_VALUES.each{|firstValue|
      SECOND_LINE_REPLACE_VALUES.each{|secondValue|
         THIRD_LINE_REPLACE_VALUES.each{|thirdValue|
            File.open(TEMPLATE_PATH, 'r'){|inFile|
               File.open(TEMPLATE_PATH.sub(NAME_SEARCH_PATTERN, "#{firstValue}-#{secondValue}-#{thirdValue}"), 'w'){|outFile|
                  inFile.each{|line|
                     outFile.puts(line.gsub(FIRST_LINE_SEARCH_PATTERN, firstValue).gsub(SECOND_LINE_SEARCH_PATTERN, secondValue).gsub(THIRD_LINE_SEARCH_PATTERN, thirdValue))
                  }
               }
            }
         }
      }
   }
end

if ($0 == __FILE__)
   main(ARGV)
end
