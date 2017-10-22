require 'fileutils'

# Returns: {ruleIndex: weight, ...}
# Note that MLN 1-indexes, and this will correct back to a zero-index.
def parseWeights(learningOutputPath)
   weights = {}

   File.open(learningOutputPath, 'r'){|file|
      file.each{|line|
         if (match = line.match(/^(\d+\.?\d*)\s.*\s\/\/(\d).?\d*$/))
            weights[match[2].to_i() - 1] = match[1]
         end
      }
   }

   return weights
end

def main(mlnProgramPath, learningOutputPath, outPath)
   FileUtils.mkdir_p(File.dirname(outPath))

   weights = parseWeights(learningOutputPath)
   ruleIndex = 0

   File.open(mlnProgramPath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            if (match = line.match(/^(\d+\.?\d*)(\s.*)$/))
               if (ruleIndex >= weights.size())
                  raise("Found more rules than weights.")
               end

               line = "#{weights[ruleIndex]} #{match[2]}"
               ruleIndex += 1
            end

            outFile.puts(line)
         }
      }
   }

   if (ruleIndex < weights.size())
      raise("Found more weights than rules.")
   end
end

def loadArgs(args)
   if (args.size() != 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <base mln program> <weight learning output> <out path>"
      exit(1)
   end

   mlnProgramPath = args.shift()
   learningOutputPath = args.shift()
   outPath = args.shift()

   return mlnProgramPath, learningOutputPath, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
