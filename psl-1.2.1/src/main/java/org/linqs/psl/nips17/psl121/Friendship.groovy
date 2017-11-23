package org.linqs.psl.nips17.psl121;

import org.linqs.psl.config.ConfigBundle;
import org.linqs.psl.database.DataStore;
import org.linqs.psl.database.loading.Inserter;
import org.linqs.psl.groovy.PSLModel;
import org.linqs.psl.model.predicate.StandardPredicate;
import org.linqs.psl.model.term.ConstantType;
import org.linqs.psl.utils.dataloading.InserterUtils;

import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;

public class Friendship extends Experiment {
   public Friendship(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      ConstantType idType = ConstantType.UniqueIntID;

      model.add(
         predicate: "Similar",
         types: [idType, idType]
      );

      model.add(
         predicate: "Friends",
         types: [idType, idType]
      );

      model.add(
         predicate: "Block",
         types: [idType, idType]
      );
   }

   @Override
   public void defineRules() {
      model.add(
         rule: "Block(P1, A) & Block(P2, A) & Similar(P1, P2) & P1 != P2 -> Friends(P1, P2)",
         squared: true,
         weight : 10
      );

      model.add(
         rule: "Block(P1, A) & Block(P2, A) & Block(P3, A) & Friends(P1, P2) & Friends(P2, P3) & P1 != P2 & P2 != P3 & P1 != P3 -> Friends(P1, P3)",
         squared: true,
         weight : 10
      );

      model.add(
         rule: "Block(P1, A) & Block(P2, A) & Friends(P1, P2) & P1 != P2 -> Friends(P2, P1)",
         squared: true,
         weight : 10
      );

      // Prior (only deal with values in the same block).
      model.add(
         rule: "Block(P1, A) & Block(P2, A) -> !Friends(P1, P2)",
         squared: true,
         weight : 1
      );
   }

   /**
    * Load data from text files into the DataStore. Three partitions are defined
    * and populated: observations, targets, and truth.
    * Observations contains evidence that we treat as background knowledge and
    * use to condition our inferences
    * Targets contains the inference targets - the unknown variables we wish to infer
    * Truth contains the true values of the inference variables and will be used
    * to evaluate the model's performance
    */
   @Override
   public void loadData(String dataPath) {
      Inserter inserter = dataStore.getInserter(Similar, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "similar_obs.txt").toString());

      inserter = dataStore.getInserter(Friends, targetsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "friends_targets.txt").toString());

      inserter = dataStore.getInserter(Friends, truthPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "friends_truth.txt").toString());

      // Use location as block.
      inserter = dataStore.getInserter(Block, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "location_obs.txt").toString());
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([Block, Likes]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([Friends]);
   }

   @Override
   public void eval() {
      continuousEval();
      discreteEval(0.5);
   }
}
