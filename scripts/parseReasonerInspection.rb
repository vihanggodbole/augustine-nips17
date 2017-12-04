# Parse all supplied evaluation output files and parse out the reasoner inspection.
# This assumes that all supplied files are output from reasoners inspected by the same inspector
# (ie they all have the same stats).

# TODO(eriq): This needs an enture rewrite to be more robust.
#   Predicates and number of columns should be automatically parsed.

DEFAULT_MAX_ITERATIONS = 5000

def parseFile(path, predicateName, numColumns, maxIterations)
   headers = []
   data = []

   File.open(path, 'r'){|file|
      row = []

      file.each{|line|
         if (match = line.match(/ - (?:Reasoner inspection update|#{predicateName}) -- (.+)$/))
            stats = match[1].strip().split(', ').map{|stat| stat.split(': ')}

            if (stats[0][0] == 'Iteration')
               # Skip iteration in favor of order in file.
               stats = stats[1..-1]
            end

            stats.each{|stat|
               header = stat[0]
               value = stat[1]

               if (headers.size() < numColumns)
                  headers << header
               elsif (headers[row.size()] != header)
                  raise "Inconsistent header found on line #{file.lineno} (#{row.size()}). Expected: '#{headers[row.size()]}', Found: '#{header}'"
               end

               row << value
            }

            if (row.size() == numColumns)
               data << row
               row = []
            end

            if (data.size() == maxIterations)
               break
            end
         end
      }
   }

   return headers, data
end

# Size of common prefix for multiple arrays.
def commonPrefixLength(lists)
   minLength = lists.map{|list| list.size()}.min()
   prefixLen = 0

   for i in 0...minLength
      part = nil
      same = true

      lists.each{|list|
         if (part == nil)
            part = list[i]
         elsif (part != list[i])
            same = false
            break
         end
      }

      if (same)
         prefixLen += 1
      else
         break
      end
   end

   return prefixLen
end

# Remove the common prefix and suffix from all the paths and use the remaining as an id.
def computeFileIds(inputFiles)
   if (inputFiles.size() == 0)
      return inputFiles
   end

   cleanParts = inputFiles.map{|path| File.absolute_path(path).split(File::SEPARATOR)}

   # Prefix
   trimSize = commonPrefixLength(cleanParts)
   cleanParts.map!{|parts| parts[trimSize..-1]}

   # Suffix
   cleanParts.map!{|parts| parts.reverse()}
   trimSize = commonPrefixLength(cleanParts)
   cleanParts.map!{|parts| parts[trimSize..-1]}
   cleanParts.map!{|parts| parts.reverse()}

   return cleanParts.map{|parts| parts.join(File::SEPARATOR)}
end

def main(predicateName, numColumns, maxIterations, inputFiles)
   fileIds = computeFileIds(inputFiles)

   headers = ['iteration']
   rows = []

   totalColumns = nil

   inputFiles.each_with_index{|inputFile, fileIndex|
      fileId = fileIds[fileIndex]
      columns, data = parseFile(inputFile, predicateName, numColumns, maxIterations)

      # Once we get the first set of columns, we can calculate the width.
      # Don't include the iteration.
      if (totalColumns == nil)
         totalColumns = columns.size() * inputFiles.size()
      end

      headers += columns.map{|column| "#{fileId} -- #{column}"}

      # Lengthen the table if necessary.
      if (rows.size() < data.size())
         rows += Array.new(data.size() - rows.size()){ [[nil] * totalColumns] }
      end

      # The offset into the row that this file's data starts.
      rowOffset = fileIndex * columns.size()

      data.each_with_index{|row, iteration|
         row.each_with_index{|value, index|
            rows[iteration][rowOffset + index] = value
         }
      }
   }

   puts headers.join("\t")
   rows.each_with_index{|row, iteration|
      puts ([iteration + 1] + row).join("\t")
   }
end

def loadArgs(args)
   if (args.size() < 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <target predicate> <number of stat columns> [-m maxIteration] <evalaution output file> ..."
      puts "   Parse all supplied evaluation output files and parse out the reasoner inspection."
      puts "   This assumes that all supplied files are output from reasoners inspected by the same inspector"
      puts "   (ie they all have the same stats)."
      puts "   The number of stat columns is the actual number of statistics we are looking to parse."
      exit(1)
   end

   predicateName = args.shift().upcase()
   numColumns = args.shift().to_i()

   maxIterations = DEFAULT_MAX_ITERATIONS
   if (args[0] == '-m')
      args.shift()
      maxIterations = args.shift().to_i()
   end

   return predicateName, numColumns, maxIterations, args
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
