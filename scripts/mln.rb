require 'fileutils'

module MLN
   # File infos look like: [
   #    {:name => '', :predicate => '', :hasTruth => true/false, :defaultTruth => value, :forceTrue => true},
   # ]
   # :hasTruth is whether or not the data file has a truth value at the end.
   # :defaultTruth is the truth value  to be used when :hasTruth is false, useful for target priors.
   # :forceTrue is optional and if true all evidence will be true.
   # Truth values of 0/1 are interpreted as hard truth values ("hard truth" as whatever Tuffy defines it as).
   def MLN.generateDataFile(dataDir, outPath, fileInfo)
      FileUtils.mkdir_p(File.dirname(outPath))

      File.open(outPath, 'w'){|outFile|
         fileInfo.each{|fileInfo|
            translateDataFiles(File.join(
                  dataDir, fileInfo[:name]), fileInfo[:predicate],
                  fileInfo[:hasTruth], fileInfo[:defaultTruth],
                  fileInfo[:forceTrue], outFile)
         }
      }
   end

   def MLN.translateDataFiles(path, predicate, hasTruth, defaultTruth, forceTrue, outFile)
      File.open(path, 'r'){|inFile|
         inFile.each{|line|
            parts = line.split().map{|part| part.strip()}

            truth = defaultTruth
            if (hasTruth)
               truth = parts.pop()
            end

            if (forceTrue)
               truth = '1'
            end

            if (['0', '0.0'].include?(truth))
               outFile.puts("!#{predicate}(#{parts.join(', ')})")
            elsif (['1', '1.0'].include?(truth))
               outFile.puts("#{predicate}(#{parts.join(', ')})")
            else
               outFile.puts("#{truth} #{predicate}(#{parts.join(', ')})")
            end
         }
      }
   end
end
