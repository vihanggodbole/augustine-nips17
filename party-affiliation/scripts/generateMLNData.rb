require_relative '../../scripts/mln'

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
