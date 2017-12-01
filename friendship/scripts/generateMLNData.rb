require_relative '../../scripts/mln'

FILE_INFO = [
   # {:name => 'friends_targets.txt', :predicate => 'Friends', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'location_obs.txt', :predicate => 'Block', :hasTruth => false, :defaultTruth => 1.0},
   {:name => 'similar_obs.txt', :predicate => 'Similar', :hasTruth => true, :defaultTruth => 1.0},
]

def main(dataDir, outPath)
   MLN.generateDataFile(dataDir, outPath, FILE_INFO)
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
