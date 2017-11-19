require 'fileutils'

FILE_INFO = [
   # {:name => 'friends_targets.txt', :predicate => 'Friends', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'location_obs.txt', :predicate => 'Block', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'similar_obs.txt', :predicate => 'Similar', :hasTruth => true, :defaultTruth => 1.0},
]

def parseFile(path, predicate, hasTruth, defaultTruth, outFile)
   File.open(path, 'r'){|inFile|
      inFile.each{|line|
         parts = line.split().map{|part| part.strip()}

         truth = defaultTruth
         if (hasTruth)
            truth = parts.pop()

            # if (truth == '0' || truth == '0.0')
            #    truth = '!'
            # end
         end

         outFile.puts("#{truth} #{predicate}(#{parts.join(', ')})")
      }
   }
end

def main(dataDir, outPath)
   FileUtils.mkdir_p(File.dirname(outPath))

   File.open(outPath, 'w'){|outFile|
      FILE_INFO.each{|fileInfo|
         parseFile(File.join(dataDir, fileInfo[:name]), fileInfo[:predicate], fileInfo[:hasTruth], fileInfo[:defaultTruth], outFile)
      }
   }
end

def loadArgs(args)
   if (![2, 3].include?(args.size()) || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <data dir> <out path>"
      puts "   As per MLN convention, all evidence will be put into a single file."
      exit(1)
   end

   dataDir = args.shift()
   outPath = args.shift()

   return dataDir, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
