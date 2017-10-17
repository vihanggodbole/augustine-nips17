require 'fileutils'

IN_DIR = 'raw'
OUT_BASE_DIR = 'processed'
RAW_DATA_FILENAME_PREFIX = 'socialNet'

DELIM = "\t"
PREDICATE_INDEX = 1

def readRawFile(path)
   # {predicate: [[row], ...]}
   data = Hash.new{|hash, key| hash[key] = []}

   File.open(path, 'r'){|inFile|
      inFile.each{|line|
         parts = line.split(DELIM).map{|part| part.strip()}

         # Remove the predicate.
         data[parts[PREDICATE_INDEX]] << (parts[0...PREDICATE_INDEX] + parts[(PREDICATE_INDEX + 1)...parts.size()])
      }
   }

   return data
end

# Calculate the bias predicate according to the PersonalBias function in Steve's code.
# For every party name (second param) and registeredAs value (second param), calculate the bias.
def calculateBias(data)
   data['party'].each{|partyId, partyName|
      data['registeredAs'].each{|personId, rawValue|
         rawValue = rawValue.to_f()
         finalVal = 0.0

         if (partyName == 'Republican' && rawValue < 0)
            finalVal = rawValue.abs()
         elsif (partyName == 'Democratic' && rawValue > 0)
            finalVal = rawValue
         end

         # Just leave out zero values.
         if (finalVal != 0.0)
            data['bias'] << [personId, partyId, finalVal]
         end
      }
   }
end

def calculateTargets(data, count)
   for person in 0...count
      for party in 0...2
         data['votes'] << [person, party]
      end
   end
end

def writeData(outDir, data)
   FileUtils.mkdir_p(outDir)

   data.each_pair{|predicate, rows|
      suffix = 'obs'
      if (predicate == 'votes')
         suffix = 'targets'
      end

      File.open(File.join(outDir, "#{predicate}_#{suffix}.txt"), 'w'){|file|
         file.puts(rows.map{|row| row.join("\t")}.join("\n"))
      }
   }
end

def processRawFile(path)
   match = path.match(/#{RAW_DATA_FILENAME_PREFIX}(\d+)\.txt/)
   if (match == nil)
      raise("Filename does not match known pattern: [#{path}].")
   end

   data = readRawFile(path)

   # Do some cleanup on the data.
   data['registeredAs'] = data['anon1']
   data.delete('anon1')

   # Add in the party predicate.
   data['party'] = [
      [0, 'Republican'],
      [1, 'Democratic']
   ]

   calculateBias(data)
   calculateTargets(data, match[1].to_i())

   # Remove 'registeredAs'.
   # We could also remove 'party', but we will leave it so people can look at it.
   data.delete('registeredAs')

   writeData(File.join(OUT_BASE_DIR, match[1]), data)
end

def main(args)
   Dir.glob(File.join(IN_DIR, "#{RAW_DATA_FILENAME_PREFIX}*.txt")).each{|path|
      processRawFile(path)
   }
end

if ($0 == __FILE__)
   main(ARGV)
end
