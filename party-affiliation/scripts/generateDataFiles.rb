FOLD_SEARCH_PATTERN = '__fold__'
FOLDS = [22050, 33075, 38588, 44100, 49613, 55125, 66150]

def main(templatePath, fold, outPath)
   File.open(templatePath, 'r'){|inFile|
      File.open(outPath, 'w'){|outFile|
         inFile.each{|line|
            outFile.puts(
                  line
                  .gsub(FOLD_SEARCH_PATTERN, "#{fold}")
            )
         }
      }
   }
end

def loadArgs(args)
   if (args.size() != 3 || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <model template> <out path> <fold>"
      puts "   model template - the path to the template data file to use."
      puts "   out path - the path to place the replaced template at."
      puts "   fold - the fold configuration to use. Possible values: #{FOLDS}."
      exit(1)
   end

   templatePath = args.shift()
   outPath = args.shift()
   fold = args.shift()

   if (!fold.match(/\d+/))
      puts "Bad format for fold (#{fold}), expecting integer."
      exit(3)
   end

   fold = fold.to_i()
   if (!FOLDS.include?(fold))
      puts "Unknown fold: '#{fold}'."
      exit(4)
   end

   return templatePath, fold, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
