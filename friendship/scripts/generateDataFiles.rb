require_relative 'generateFriendshipData'

SIZE_SEARCH_PATTERN = '__size__'

def main(templatePath, size, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line
                  .gsub(SIZE_SEARCH_PATTERN, "#{'%04d' % size}")
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <size>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   size - the size (number of people) to use."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   size = args.shift()

   if (!size.match(/\d+/))
      puts "Bad format for size (#{size}), expecting integer."
      exit(3)
   end
   size = size.to_i()

   return templatePath, size, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
