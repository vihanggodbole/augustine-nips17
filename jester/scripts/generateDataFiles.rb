FOLD_SEARCH_PATTERN = '__fold__'
METHOD_SEARCH_PATTERN = '__type__'

FOLDS =  (0...10).to_a()
METHODS = ['learn', 'eval']

def main(templatePath, fold, method, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line
                  .gsub(FOLD_SEARCH_PATTERN, "#{fold}")
                  .gsub(METHOD_SEARCH_PATTERN, method)
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 4 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <fold> <method>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   fold - the fold configuration to use. Possible values: #{FOLDS}."
      puts "   method - the psl method to use. Possible values: #{METHODS}."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   fold = args.shift()
   method = args.shift()

   if (!fold.match(/\d+/))
      puts "Bad format for fold (#{fold}), expecting integer."
      exit(3)
   end

   fold = fold.to_i()
   if (!FOLDS.include?(fold))
      puts "Unknown fold: '#{fold}'."
      exit(4)
   end

   if (!METHODS.include?(method))
      puts "Unknown method: '#{method}'."
      exit(5)
   end

   return templatePath, fold, method, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
