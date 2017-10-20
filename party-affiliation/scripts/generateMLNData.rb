require 'fileutils'

FILE_INFO = [
   {:name => 'bias_obs.txt', :predicate => 'Bias', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'boss_obs.txt', :predicate => 'Boss', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'idol_obs.txt', :predicate => 'Idol', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'knows_obs.txt', :predicate => 'Knows', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'knowswell_obs.txt', :predicate => 'KnowsWell', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'mentor_obs.txt', :predicate => 'Mentor', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'olderRelative_obs.txt', :predicate => 'OlderRelative', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'party_obs.txt', :predicate => 'Party', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'votes_targets.txt', :predicate => 'Votes', :hasTruth => false, :defaultTruth => 0.01},
]

def parseFile(path, predicate, hasTruth, defaultTruth, outFile)
   File.open(path, 'r'){|inFile|
      inFile.each{|line|
         parts = line.split().map{|part| part.strip()}

         truth = defaultTruth
         if (hasTruth)
            truth = parts.pop()
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
   if (args.size() != 2 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
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
