NUMBER_REGEX = '(\d+\.\d+)'
STATS = ['MAE', 'MSE', 'Accuracy', 'Error', 'Positive Class Precision', 'Positive Class Recall', 'Negative Class Precision', 'Negative Class Recall']

def parseOutputForStats(path)
   stats = []

   File.open(path, 'r'){|file|
      file.each{|line|
         line = line.strip()

         if (match = line.match(/Continuous evaluation results for RATING -- MAE: #{NUMBER_REGEX}, MSE: #{NUMBER_REGEX}$/))
            stats += match[1..2].map{|val| val.to_f()}
         elsif (match = line.match(/Discrete evaluation results for RATING -- Accuracy: #{NUMBER_REGEX}, Error: #{NUMBER_REGEX}, Positive Class Precision: #{NUMBER_REGEX}, Positive Class Recall: #{NUMBER_REGEX}, Negative Class Precision: #{NUMBER_REGEX}, Negative Class Recall: #{NUMBER_REGEX}/))
            stats += match[1..6].map{|val| val.to_f()}
         end
      }
   }

   return stats
end

def main(paths)
   sumStats = [0.0] * STATS.size()

   puts "#{STATS.join("\t")}\tpath"
   paths.each{|path|
      stats = parseOutputForStats(path)
      puts "#{stats.join("\t")}\t#{path}"

      stats.each_index{|i|
         sumStats[i] += stats[i]
      }
   }

   puts "#{sumStats.map{|val| val / paths.size()}.join("\t")}\tmean"
end

def loadArgs(args)
   if (args.size() < 1 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <output file> ..."
      puts "   output file - the output from an evaluation run of PSL."
      exit(1)
   end

   return args
end

if ($0 == __FILE__)
   main(loadArgs(ARGV))
end
