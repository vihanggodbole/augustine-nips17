require 'fileutils'

EVAL_OUTPUT_FILENAME = 'out-eval.txt'

HEADERS = [
   'Num Groundings',
   'Data Loading',
   'Grounding',
   'Inference',
   'Comitting Results'
]
NUM_GROUNDINGS_INDEX = 0
DATA_LOADING_INDEX = 1
GROUNDING_INDEX = 2
INFERENCE_INDEX = 3
COMITTING_RESULTS_INDEX = 4

# We know we are in a run's output directry when we see this file.
SIGNAL_FILE = EVAL_OUTPUT_FILENAME

def parsePSLRun(path, runId)
   stats = Array.new(HEADERS.size(), -1)

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      startTime = nil

      file.each{|line|
         line.strip!()

         if (match = line.match(/^(\d+) .* - Loading data for.*$/))
            if (startTime != nil)
               next
            end

            time = match[1].to_i()
            startTime = time
         elsif (match = line.match(/^(\d+) .* - Data loading complete$/))
            time = match[1].to_i()
            stats[DATA_LOADING_INDEX] = time - startTime
         elsif (match = line.match(/^(\d+) .* - Grounding out model\.$/))
            time = match[1].to_i()
            startTime = time
         elsif (match = line.match(/^(\d+) .* - Beginning inference\.$/))
            time = match[1].to_i()
            stats[GROUNDING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/^(\d+) .* - Initializing objective terms for (\d+) ground kernels$/))
            time = match[1].to_i()
            stats[NUM_GROUNDINGS_INDEX] = match[2].to_i()
         elsif (match = line.match(/^(\d+) .* - Optimization completed in.*$/))
            time = match[1].to_i()
            stats[INFERENCE_INDEX] = time - startTime
         elsif (match = line.match(/^(\d+) .* - Inference complete. Writing results to Database.$/))
            time = match[1].to_i()
            startTime = time
         elsif (match = line.match(/^(\d+) .* - Inference Complete$/))
            time = match[1].to_i()
            stats[COMITTING_RESULTS_INDEX] = time - startTime
         end
      }
   }

   return stats
end

def parseTuffyRun(path, runId)
   stats = Array.new(HEADERS.size(), -1)

   File.open(File.join(path, EVAL_OUTPUT_FILENAME), 'r'){|file|
      startTime = nil

      file.each{|line|
         line.strip!()

         if (match = line.match(/^(\d+)\s+>>> Parsing evidence file:.*$/))
            time = match[1].to_i()
            startTime = time
         elsif (match = line.match(/^(\d+)\s+>>> Grounding...$/))
            time = match[1].to_i()
            stats[DATA_LOADING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/^(\d+)\s+### atoms = ([\d,]+); clauses = ([\d,]+)/))
            time = match[1].to_i()
            stats[NUM_GROUNDINGS_INDEX] = match[3].gsub(',', '').to_i()
         elsif (match = line.match(/^(\d+)\s+>>> Grouping Components into Buckets...$/))
            time = match[1].to_i()
            stats[GROUNDING_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/^(\d+)\s+flushing states of/))
            time = match[1].to_i()
            stats[INFERENCE_INDEX] = time - startTime
            startTime = time
         elsif (match = line.match(/^(\d+)\s+>>> Cleaning up temporary data$/))
            time = match[1].to_i()
            stats[COMITTING_RESULTS_INDEX] = time - startTime
         end
      }
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
      if (runId.include?('psl'))
         return [runId + parsePSLRun(path, runId)]
      elsif (runId.include?('tuffy'))
         return [runId + parseTuffyRun(path, runId)]
      else
         puts "ERROR: Unknown run type: '#{path}'."
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
      results += parseDir(path).map{|stats| [experiment] + stats}
   }

   puts results.sort().map{|stats| stats.join("\t")}.join("\n")
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
