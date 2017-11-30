# This is for parsing results specific to this experiment.
# More general parsing scripts can be found in ../scripts.

require_relative '../../scripts/timings'

DATASETS = ['citeseer', 'cora']
FOLDS = (0...20).to_a()
TARGET_METHODS = ['psl-admm-h2', 'psl-maxwalksat-h2', 'psl-mcsat-h2', 'tuffy']

if ($0 == __FILE__)
   # Parse args
   args = ARGV

   if (args.size() > 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} [base experiment dir]"
      puts "   Will use the parent of the directory where this script lives if one it not provided."
      exit(1)
   end

   baseDir = File.dirname(File.dirname(File.absolute_path($0)))
   if (args.size() > 0)
      baseDir = args.shift()
   end

   timing = Timing.new(baseDir, TARGET_METHODS, DATASETS.size(), FOLDS.size())
   stats = timing.parse()
   timing.printStats(stats, true)
end
