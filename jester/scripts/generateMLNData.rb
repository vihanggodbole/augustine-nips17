require_relative '../../scripts/mln'

LEARN_FILE_INFO = [
   {:name => 'avgJokeRatingObs_obs.txt', :predicate => 'AvgJokeRatingObs', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'avgUserRatingObs_obs.txt', :predicate => 'AvgUserRatingObs', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'joke_obs.txt', :predicate => 'Joke', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'rating_obs.txt', :predicate => 'Rating', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'ratingPrior_obs.txt', :predicate => 'RatingPrior', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'simObsRating_obs.txt', :predicate => 'SimObsRating', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'user_obs.txt', :predicate => 'User', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'rating_truth.txt', :predicate => 'Rating', :hasTruth => true, :defaultTruth => 1.0},
]

EVAL_FILE_INFO = [
   {:name => 'avgJokeRatingObs_obs.txt', :predicate => 'AvgJokeRatingObs', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'avgUserRatingObs_obs.txt', :predicate => 'AvgUserRatingObs', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'joke_obs.txt', :predicate => 'Joke', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'rating_obs.txt', :predicate => 'Rating', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'ratingPrior_obs.txt', :predicate => 'RatingPrior', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'simObsRating_obs.txt', :predicate => 'SimObsRating', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'user_obs.txt', :predicate => 'User', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'rating_targets.txt', :predicate => 'Rating', :hasTruth => false, :defaultTruth => 0.5},
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
