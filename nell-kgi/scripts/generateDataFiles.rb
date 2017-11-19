METHOD_SEARCH_PATTERN = '__type__'
METHODS = ['learn', 'eval']

def main(templatePath, method, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line
                  .gsub(METHOD_SEARCH_PATTERN, "#{method}")
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <method>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   method - the psl method to use. Possible values: #{METHODS}."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   method = args.shift()

   if (!METHODS.include?(method))
      puts "Unknown method: '#{method}'."
      exit(4)
   end

   return templatePath, method, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
