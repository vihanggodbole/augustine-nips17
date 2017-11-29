require 'fileutils'
require 'set'

# Go through all the run output and grab all the accuracy measures.
# Since each experiment may have different metrics, each dataset will
# be handled independently.
# This is a very general version.
# More specific scripts can be found in each experiment's script directory.

EVAL_OUTPUT_FILENAME = 'out-eval.txt'

BASE_HEADERS = ['Dataset', 'Method', 'Sub-Dataset', 'Fold']
NUM_REGEX = '-?\d+(?:\.\d+)?'

# We know we are in a run's output directory when we see this file.
SIGNAL_FILE = EVAL_OUTPUT_FILENAME

def mean(values)
   return values.reduce(:+) / values.size().to_f()
end

# Make sure that all run ids are 3 sections long: Method, Dataset, Fold
def normalizeRunIds(results, experiment)
   results.each{|runId, stats|
      if (experiment == 'epinions')
         runId.insert(1, '')
      elsif (experiment == 'friendship')
         runId.insert(2, '')
      elsif (experiment == 'image-reconstruction')
         runId.insert(2, '')
      elsif (experiment == 'jester')
         runId.insert(1, '')
      elsif (experiment == 'nell-kgi')
         runId.insert(1, '')
         runId.insert(1, '')
      elsif (experiment == 'party-affiliation')
         runId.insert(2, '')
      elsif (experiment == 'party-affiliation-scaling')
         runId.insert(2, '')
      end

      # Also put in the dataset/experiment.
      runId.insert(0, experiment)
   }
end

def parsePSLRun(path, runId)
   stats = {}

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      file.each{|line|
         line.strip!()

         if (match = line.match(/ - Continuous evaluation results for (\w+) -- MAE: (#{NUM_REGEX}), MSE: (#{NUM_REGEX})$/))
            predicate = match[1]
            stats["#{predicate} MAE"] = match[2].to_f()
            stats["#{predicate} MSE"] = match[3].to_f()
         elsif (match = line.match(/ - Discrete evaluation results for (\w+) -- Accuracy: (#{NUM_REGEX}), Error: (#{NUM_REGEX}), Positive Class Precision: (#{NUM_REGEX}), Positive Class Recall: (#{NUM_REGEX}), Negative Class Precision: (#{NUM_REGEX}), Negative Class Recall: (#{NUM_REGEX}),$/))
            predicate = match[1]
            stats["#{predicate} Accuracy"] = match[2].to_f()
            stats["#{predicate} Total Error"] = match[3].to_f()
            stats["#{predicate} Positive Class Precision"] = match[4].to_f()
            stats["#{predicate} Positive Class Recall"] = match[5].to_f()
            stats["#{predicate} Negative Class Precision"] = match[6].to_f()
            stats["#{predicate} Negative Class Recall"] = match[7].to_f()
         end
      }
   }

   return stats
end

def parsePSL2Run(path, runId)
   stats = {}

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      file.each{|line|
         line.strip!()

      }
   }

   return stats
end

def parseTuffyRun(path, runId)
   stats = {}

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      file.each{|line|
         line.strip!()

      }
   }

   return stats
end

# Recursively descend until we see SIGNAL_FILE.
# Every directory we descend past on the way becomes part of the experiment run identifier.
# Returns: [[runId, {header => value}], ...]
def parseDir(path, runId = [])
   if (!File.exists?(File.join(path, SIGNAL_FILE)))
      # Dive deeper!
      results = []

      Dir.entries(path).each{|name|
         if (['.', '..'].include?(name))
            next
         end

         childPath = File.join(path, name)
         if (!File.directory?(childPath))
            next
         end

         newRunId = runId.clone()

         # For sorting reasons, make name an int if possible.
         if (name.match(/^\d+$/))
            name = name.to_i()
         end
         newRunId << name

         results += parseDir(childPath, newRunId)
      }

      return results
   else
      methodId = runId[0].to_s()

      # This dir has the results.
      # Make sure to wrap the results in an extra array.
      if (methodId.match(/^psl-\w+-(h2|postgres)$/))
         return [[runId, parsePSLRun(path, runId)]]
      elsif (methodId =='psl-2.0')
         return [[runId, parsePSL2Run(path, runId)]]
      elsif (methodId =='tuffy')
         return [[runId, parseTuffyRun(path, runId)]]
      elsif (methodId == 'psl-1.2.1')
         return [[runId, parsePSLRun(path, runId)]]
      else
         raise("ERROR: Unknown run type: '#{path}'.")
      end
   end
end

def main(baseDir)
   # Look for 'out' directories.
   Dir[File.join(baseDir, '*', 'out')].each{|path|
      if (!File.directory?(path))
         next
      end

      experiment = File.basename(File.dirname(path))

      # [[runId, {header => value}], ...]
      experimentResults = parseDir(path)
      if (experimentResults.size() == 0)
         next
      end

      normalizeRunIds(experimentResults, experiment)

      # Collect the headers from every experiment (just in case some have missing values).
      headers = Set.new()
      experimentResults.each{|runId, stats|
         headers += stats.keys()
      }
      headers = headers.to_a().sort()

      # We will want to aggregate by the first three values of the run id.
      # {runId[0...3] => {header => [value, ...], ...}, ...}
      sums = Hash.new{|hash, key| hash[key] = Hash.new{|innerHash, innerKey| innerHash[innerKey] = []}}

      puts "--- #{experiment} Raw --"
      puts (BASE_HEADERS + headers).join("\t")

      experimentResults.sort().each{|runId, stats|
         row = runId

         headers.each{|header|
            if (stats.include?(header))
               row << stats[header]
               sums[row[0...3]][header] << stats[header]
            else
               row << -1
            end
         }

         puts row.join("\t")
      }

      puts "--- #{experiment} Aggregated --"
      puts (BASE_HEADERS[0...3] + BASE_HEADERS[4..-1] + headers).join("\t")
      sums.keys().sort().each{|id|
         row = id
         stats = sums[id]

         headers.each{|header|
            if (stats.include?(header))
               row << mean(stats[header])
            else
               row << -1
            end
         }

         puts row.join("\t")
      }
   }
end

def loadArgs(args)
   if (args.size() != 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <base project dir>"
      puts "   The provided project directory should be the one that contains all the"
      puts "   individual experiment directories (which in turn contain 'out' directories)."
      exit(1)
   end

   baseDir = args.shift()

   return baseDir
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
