require_relative '../../scripts/mln'

LEARN_FILE_INFO = [
   {:name => 'hasCat_obs.txt', :predicate => 'HasCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'hasCat_truth.txt', :predicate => 'HasCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'link_obs.txt', :predicate => 'Link', :hasTruth => true, :defaultTruth => 1.0},
]

EVAL_FILE_INFO = [
   {:name => 'hasCat_obs.txt', :predicate => 'HasCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'hasCat_targets.txt', :predicate => 'HasCat', :hasTruth => false, :defaultTruth => 0.01},
   {:name => 'link_obs.txt', :predicate => 'Link', :hasTruth => true, :defaultTruth => 1.0},
]

def main(dataDir, outPath, fileInfo)
   MLN.generateDataFile(dataDir, outPath, fileInfo)
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
