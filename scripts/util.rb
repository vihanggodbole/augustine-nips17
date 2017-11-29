# General utils for scripts.

module Util
   def Util.mean(values)
      return values.reduce(:+) / values.size().to_f()
   end

   # Gives two args to the block: dirent name and dirent path.
   # Does not include '.' or '..'.
   def Util.listDir(dir, &block)
      Dir.entries(dir).each{|name|
         if (['.', '..'].include?(name))
            next
         end

         block.call(name, File.join(dir, name))
      }
   end
end
