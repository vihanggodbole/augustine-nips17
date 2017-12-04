require_relative '../../scripts/mln'

LEARN_FILE_INFO = [
   {:name => 'east_obs.txt', :predicate => 'East', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'horizontalMirror_obs.txt', :predicate => 'HorizontalMirror', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'north_obs.txt', :predicate => 'North', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'picture_obs.txt', :predicate => 'Picture', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'pixelBrightness_obs.txt', :predicate => 'PixelBrightness', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'verticalMirror_obs.txt', :predicate => 'VerticalMirror', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'pixelBrightness_truth.txt', :predicate => 'PixelBrightness', :hasTruth => true, :defaultTruth => 1.0},
]

EVAL_FILE_INFO = [
   {:name => 'east_obs.txt', :predicate => 'East', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'horizontalMirror_obs.txt', :predicate => 'HorizontalMirror', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'north_obs.txt', :predicate => 'North', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'picture_obs.txt', :predicate => 'Picture', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'pixelBrightness_obs.txt', :predicate => 'PixelBrightness', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'verticalMirror_obs.txt', :predicate => 'VerticalMirror', :hasTruth => true, :defaultTruth => 1.0},
   # {:name => 'pixelBrightness_targets.txt', :predicate => 'PixelBrightness', :hasTruth => false, :defaultTruth => 1.0},
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
