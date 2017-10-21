require 'fileutils'

LEARN_FILE_INFO = [
   {:name => 'knows_obs.txt', :predicate => 'Knows', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'prior_obs.txt', :predicate => 'Prior', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'trusts_obs.txt', :predicate => 'Trusts', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'trusts_truth.txt', :predicate => 'Trusts', :hasTruth => true, :defaultTruth => 1.0},
]

EVAL_FILE_INFO = [
   {:name => 'knows_obs.txt', :predicate => 'Knows', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'prior_obs.txt', :predicate => 'Prior', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'trusts_obs.txt', :predicate => 'Trusts', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'trusts_target.txt', :predicate => 'Trusts', :hasTruth => false, :defaultTruth => 1.0},
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

def main(dataDir, outPath, fileInfo)
   FileUtils.mkdir_p(File.dirname(outPath))

   File.open(outPath, 'w'){|outFile|
      fileInfo.each{|fileInfo|
         parseFile(File.join(dataDir, fileInfo[:name]), fileInfo[:predicate], fileInfo[:hasTruth], fileInfo[:defaultTruth], outFile)
      }
   }
end

def loadArgs(args)
   if (args.size() != 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <data dir> <out path> <'learn' | 'eval'>"
      puts "   As per MLN convention, all evidence will be put into a single file."
      exit(1)
   end

   dataDir = args.shift()
   outPath = args.shift()
   method = args.shift()

   if (!['learn', 'eval'].include?(method))
      puts "ERROR: Bad method (#{method}), Expecting 'learn' or 'eval'."
      exit(2)
   end

   fileInfo = LEARN_FILE_INFO
   if (method == 'eval')
      fileInfo = EVAL_FILE_INFO
   end

   return dataDir, outPath, fileInfo
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
