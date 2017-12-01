# Get the results from very specific experiments.

require_relative 'timings'

require_relative '../collective-classification/scripts/computeResults'
require_relative '../epinions/scripts/computeResults'
require_relative '../jester/scripts/computeResults'
require_relative '../nell-kgi/scripts/computeResults'

TARGET_METHODS = ['psl-admm-postgres', 'psl-maxwalksat-postgres', 'psl-mcsat-postgres', 'tuffy']

EXPERIMENTS = [
   {
      :id => 'collective-classification',
      :numDatasets => 2,
      :numFolds => 20,
      :evaluator => CollectiveClassificationEval
   },
   {
      :id => 'epinions',
      :numDatasets => 0,
      :numFolds => 8,
      :evaluator => EpinionsEvaluation
   },
   {
      :id => 'jester',
      :numDatasets => 0,
      :numFolds => 10,
      :evaluator => JesterEval
   },
   {
      :id => 'nell-kgi',
      :numDatasets => 0,
      :numFolds => 0,
      :evaluator => NellKGIEval
   },
]

def main(baseDir)
   EXPERIMENTS.each{|experiment|
      path = File.join(baseDir, experiment[:id])

      timing = Timing.new(path, TARGET_METHODS, experiment[:numDatasets], experiment[:numFolds])
      stats = timing.parse()

      rows = timing.flattenStats(stats, true)
      header = timing.getHeader()

      # Add in the accuracy stats.

      accuracyRows = experiment[:evaluator].eval(path)

      # Matchup the timing output with the accuracy output.
      if (experiment[:numDatasets] > 0)
         matchingRows = 2
      else
         matchingRows = 1
      end

      rows.each{|row|
         accuracyRows.each{|accuracyRow|
            if (row[0...matchingRows] == accuracyRow[0...matchingRows])
               row.concat(accuracyRow[matchingRows..-1])
            end
         }
      }

      header += experiment[:evaluator].getHeader[matchingRows..-1]

      puts (['experiment'] + header).join("\t")
      puts rows.map{|row| ([experiment[:id]] + row).join("\t")}.join("\n")
      puts ''
   }
end

def loadArgs(args)
   if (args.size() > 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} [base experiment dir]"
      puts "   Will use the parent of the directory where this script lives if one it not provided."
      exit(1)
   end

   baseDir = File.dirname(File.dirname(File.absolute_path($0)))
   if (args.size() > 0)
      baseDir = args.shift()
   end

   return baseDir
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
