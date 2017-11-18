require 'fileutils'

EVAL_OUTPUT_FILENAME = 'out-eval.txt'

HEADERS = [
   'Num Groundings',
   'Data Loading',
   'Grounding',
   'Inference',
   'Comitting Results',
   'Total'
]
NUM_GROUNDINGS_INDEX = 0
DATA_LOADING_INDEX = 1
GROUNDING_INDEX = 2
INFERENCE_INDEX = 3
COMITTING_RESULTS_INDEX = 4
TOTAL_INDEX = 5

# We know we are in a run's output directry when we see this file.
SIGNAL_FILE = EVAL_OUTPUT_FILENAME

# Take in an array of arrays of values and mean all the columns.
def meanColumns(rows)
   sums = Array.new(rows[0].size(), 0)

   rows.each{|row|
      row.each_index{|i|
         sums[i] += row[i]
      }
   }

   return sums.map{|sum| sum / rows.size().to_f()}
end

# Make sure that all run ids are 4 sections long: Framework, Dataset, Fold
def normalizeRunIds(results, experiment)
   results.each{|result|
      if (experiment == 'epinions')
         result.insert(1, '')
      elsif (experiment == 'image-reconstruction')
         result.insert(2, '')
      elsif (experiment == 'jester')
         result.insert(1, '')
      elsif (experiment == 'party-affiliation')
         result.insert(2, '')
      end
   }
end

def parsePSL2Run(path, runId)
   stats = Array.new(HEADERS.size(), -1)

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      startTime = nil
      time = nil

      file.each{|line|
         line.strip!()

         if (match = line.match(/^(\d+)\s/))
            time = match[1].to_i()
         end

         if (match = line.match(/- Determining max partition, no partitions found null$/))
            startTime = time
         elsif (match = line.match(/- data:: loading:: ::done$/))
            stats[DATA_LOADING_INDEX] = time - startTime
         elsif (match = line.match(/- Grounding out model\.$/))
            startTime = time
         elsif (match = line.match(/- Beginning inference\.$/))
            stats[GROUNDING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/- Initializing objective terms for (\d+) ground kernels$/))
            stats[NUM_GROUNDINGS_INDEX] = match[1].to_i()
         elsif (match = line.match(/- Optimization completed in.*$/))
            stats[INFERENCE_INDEX] = time - startTime
         elsif (match = line.match(/- Inference complete. Writing results to Database.$/))
            startTime = time
         elsif (match = line.match(/- operation::infer ::done$/))
            stats[COMITTING_RESULTS_INDEX] = time - startTime
         end
      }

      stats[TOTAL_INDEX] = time
   }

   return stats
end

def parsePSLRun(path, runId)
   stats = Array.new(HEADERS.size(), -1)

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      startTime = nil
      time = nil

      file.each{|line|
         line.strip!()

         if (match = line.match(/^(\d+)\s/))
            time = match[1].to_i()
         end

         if (match = line.match(/- Loading data for.*$/))
            if (startTime != nil)
               next
            end

            startTime = time
         elsif (match = line.match(/- Data loading complete$/))
            stats[DATA_LOADING_INDEX] = time - startTime
         elsif (match = line.match(/- Grounding out model\.$/))
            startTime = time
         elsif (match = line.match(/- Beginning inference\.$/))
            stats[GROUNDING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/- Initializing objective terms for (\d+) ground kernels$/))
            stats[NUM_GROUNDINGS_INDEX] = match[1].to_i()
         elsif (match = line.match(/- Optimization completed in.*$/))
            stats[INFERENCE_INDEX] = time - startTime
         elsif (match = line.match(/- Inference complete. Writing results to Database.$/))
            startTime = time
         elsif (match = line.match(/- Inference Complete$/))
            stats[COMITTING_RESULTS_INDEX] = time - startTime
            stats[TOTAL_INDEX] = time
         end
      }
   }

   return stats
end

def parseTuffyRun(path, runId)
   stats = Array.new(HEADERS.size(), -1)

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      startTime = nil
      time = nil

      file.each{|line|
         line.strip!()

         if (match = line.match(/^(\d+)\s/))
            time = match[1].to_i()
         end

         if (match = line.match(/\s+>>> Parsing evidence file:.*$/))
            startTime = time
         elsif (match = line.match(/\s+>>> Grounding...$/))
            stats[DATA_LOADING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/\s+### atoms = ([\d,]+); clauses = ([\d,]+)/))
            stats[NUM_GROUNDINGS_INDEX] = match[2].gsub(',', '').to_i()
         elsif (match = line.match(/\s+>>> Grouping Components into Buckets...$/))
            stats[GROUNDING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/\s+flushing states of/))
            stats[INFERENCE_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/\s+>>> Cleaning up temporary data$/))
            stats[COMITTING_RESULTS_INDEX] = time - startTime
         end
      }

      stats[TOTAL_INDEX] = time
   }

   return stats
end

# Recursivley descend until we see SIGNAL_FILE.
# Every directory we descend past on the way becomes part of the experiment run identifier.
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
      # This dir has the results.
      # Make sure to wrap the results in an extra array.
      if (runId.include?('psl') || runId.include?('psl-postgres'))
         return [runId + parsePSLRun(path, runId)]
      elsif (runId.include?('psl-2.0'))
         return [runId + parsePSL2Run(path, runId)]
      elsif (runId.include?('tuffy'))
         return [runId + parseTuffyRun(path, runId)]
      else
         raise("ERROR: Unknown run type: '#{path}'.")
      end
   end
end

def main(baseDir)
   results = []

   # Look for 'out' directories.
   Dir[File.join(baseDir, '*', 'out')].each{|path|
      if (!File.directory?(path))
         next
      end

      experiment = File.basename(File.dirname(path))

      # puts "Parsing out directory: '#{path}'"
      experimentResults = parseDir(path)

      normalizeRunIds(experimentResults, experiment)

      results += experimentResults.map{|stats| [experiment] + stats}
   }

   puts results.sort().map{|stats| stats.join("\t")}.join("\n")

   # Aggregate folds.
   # Aggregate all results that have matching first three columns.
   aggregate = Hash.new{|hash, key| hash[key] = []}
   results.each{|result|
      key, values = result[0...3], result[4..-1]
      aggregate[key] << values
   }
   aggregate = aggregate.to_a().map{|key, values| key + meanColumns(values).map{|val| val.to_i()}}

   puts "---"
   puts aggregate.sort().map{|stats| stats.join("\t")}.join("\n")
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
