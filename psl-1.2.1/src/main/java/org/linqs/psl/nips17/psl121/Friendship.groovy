package org.linqs.psl.nips17.psl121;

import edu.umd.cs.psl.config.ConfigBundle;
import edu.umd.cs.psl.database.DataStore;
import edu.umd.cs.psl.database.loading.Inserter;
import edu.umd.cs.psl.groovy.PSLModel;
import edu.umd.cs.psl.model.predicate.StandardPredicate;
import edu.umd.cs.psl.model.argument.ArgumentType;
import edu.umd.cs.psl.ui.loading.InserterUtils;

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
      model.add(
         predicate: "Similar",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Friends",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Block",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );
   }

   @Override
   public double[] getDefaultWeights() {
      return [10.0, 10.0, 10.0, 1.0];
   }

   @Override
   public void defineRules(double[] weights) {
      model.add(
         rule: ( Block(P1, A) & Block(P2, A) & Similar(P1, P2) & (P1 - P2) ) >> Friends(P1, P2),
         squared: true,
         weight: weights[0]
      );

      model.add(
         rule: ( Block(P1, A) & Block(P2, A) & Block(P3, A) & Friends(P1, P2) & Friends(P2, P3) & (P1 - P2) & (P2 - P3) & (P1 - P3) ) >> Friends(P1, P3),
         squared: true,
         weight: weights[1]
      );

      model.add(
         rule: ( Block(P1, A) & Block(P2, A) & Friends(P1, P2) & (P1 - P2) ) >> Friends(P2, P1),
         squared: true,
         weight: weights[2]
      );

      model.add(
         rule: ~Friends(P1, P2),
         squared: true,
         weight: weights[3]
      );
   }

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
