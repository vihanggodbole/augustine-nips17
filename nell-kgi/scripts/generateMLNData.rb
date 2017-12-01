require_relative '../../scripts/mln'

FILE_INFO = [
   {:name => 'CANDCAT_CBL_obs.txt', :predicate => 'CandCat_CBL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_CMC_obs.txt', :predicate => 'CandCat_CMC', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_CPL_obs.txt', :predicate => 'CandCat_CPL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_GENERAL_obs.txt', :predicate => 'CandCat_General', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_MORPH_obs.txt', :predicate => 'CandCat_Morph', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_obs.txt', :predicate => 'CandCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDCAT_SEAL_obs.txt', :predicate => 'CandCat_SEAL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDREL_CBL_obs.txt', :predicate => 'CandRel_CBL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDREL_CPL_obs.txt', :predicate => 'CandRel_CPL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDREL_GENERAL_obs.txt', :predicate => 'CandRel_General', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDREL_obs.txt', :predicate => 'CandRel', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CANDREL_SEAL_obs.txt', :predicate => 'CandRel_SEAL', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'CAT_obs.txt', :predicate => 'Cat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'DOMAIN_obs.txt', :predicate => 'Domain', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'INV_obs.txt', :predicate => 'Inv', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'MUT_obs.txt', :predicate => 'Mut', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'PROMCAT_GENERAL_obs.txt', :predicate => 'PromCat_General', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'PROMREL_GENERAL_obs.txt', :predicate => 'PromRel_General', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'RANGE2_obs.txt', :predicate => 'Range2', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'REL_obs.txt', :predicate => 'Rel', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'RMUT_obs.txt', :predicate => 'RMut', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'RSUB_obs.txt', :predicate => 'RSub', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'SAMEENTITY_obs.txt', :predicate => 'SameEntity', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'SUB_obs.txt', :predicate => 'Sub', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'TRCAT_obs.txt', :predicate => 'TRCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'TRREL_obs.txt', :predicate => 'TRRel', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'VALCAT_obs.txt', :predicate => 'ValCat', :hasTruth => true, :defaultTruth => 1.0},
   {:name => 'VALREL_obs.txt', :predicate => 'ValRel', :hasTruth => true, :defaultTruth => 1.0},

   {:name => 'CAT_targets.txt', :predicate => 'Cat', :hasTruth => false, :defaultTruth => 0.00027},
   {:name => 'REL_targets.txt', :predicate => 'Rel', :hasTruth => false, :defaultTruth => 0.00027},

   # {:name => 'CAT_truth.txt', :predicate => 'Cat', :hasTruth => true, :defaultTruth => 1.0},
   # {:name => 'REL_truth.txt', :predicate => 'Rel', :hasTruth => true, :defaultTruth => 1.0},
]

def main(dataDir, outPath)
   MLN.generateDataFile(dataDir, outPath, FILE_INFO)
end

def loadArgs(args)
   if (![2, 3].include?(args.size()) || args.map{|arg| arg.gsub('-', '').downcase()}.include?('help'))
      puts "USAGE: ruby #{$0} <data dir> <out path>"
      puts "   As per MLN convention, all evidence will be put into a single file."
      exit(1)
   end

   dataDir = args.shift()
   outPath = args.shift()

   return dataDir, outPath
end

if ($0 == __FILE__)
   main(*loadArgs(ARGV))
end
