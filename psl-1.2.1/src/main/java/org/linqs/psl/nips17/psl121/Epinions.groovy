package org.linqs.psl.nips17.psl121;

import edu.umd.cs.psl.config.ConfigBundle;
import edu.umd.cs.psl.database.DataStore;
import edu.umd.cs.psl.database.loading.Inserter;
import edu.umd.cs.psl.groovy.PSLModel;
import edu.umd.cs.psl.groovy.PredicateConstraint;
import edu.umd.cs.psl.model.predicate.StandardPredicate;
import edu.umd.cs.psl.model.argument.ArgumentType;
import edu.umd.cs.psl.ui.loading.InserterUtils;

import java.nio.file.Paths;
import java.util.HashSet;
import java.util.Set;

public class Epinions extends Experiment {
   public Epinions(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      model.add(
         predicate: "Knows",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Prior",
         types: [ArgumentType.UniqueID]
      );

      model.add(
         predicate: "Trusts",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );
   }

   @Override
   public double[] getDefaultWeights() {
      double[] weights = new double[19];
      for (int i = 0; i < weights.length; i++) {
         weights[i] = 1.0;
      }

      return weights;
   }

   @Override
   public void defineRules(double[] weights) {
      model.add(
         rule: ( Knows(A, B) & Knows(B, C) & Knows(A, C) & Trusts(A, B) & Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[0]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(B, C) & Knows(A, C) & Trusts(A, B) & ~Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[1]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(B, C) & Knows(A, C) & ~Trusts(A, B) & Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[2]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(B, C) & Knows(A, C) & ~Trusts(A, B) & ~Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[3]
      );

      model.add(
         rule: ( Knows(A, B) & Knows(C, B) & Knows(A, C) & Trusts(A, B) & Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[4]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(C, B) & Knows(A, C) & Trusts(A, B) & ~Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[5]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(C, B) & Knows(A, C) & ~Trusts(A, B) & Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[6]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(C, B) & Knows(A, C) & ~Trusts(A, B) & ~Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[7]
      );

      model.add(
         rule: ( Knows(B, A) & Knows(B, C) & Knows(A, C) & Trusts(B, A) & Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[8]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(B, C) & Knows(A, C) & Trusts(B, A) & ~Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[9]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(B, C) & Knows(A, C) & ~Trusts(B, A) & Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[10]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(B, C) & Knows(A, C) & ~Trusts(B, A) & ~Trusts(B, C) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[11]
      );

      model.add(
         rule: ( Knows(B, A) & Knows(C, B) & Knows(A, C) & Trusts(B, A) & Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[12]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(C, B) & Knows(A, C) & Trusts(B, A) & ~Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[13]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(C, B) & Knows(A, C) & ~Trusts(B, A) & Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> ~Trusts(A, C),
         squared: false,
         weight: weights[14]
      );
      model.add(
         rule: ( Knows(B, A) & Knows(C, B) & Knows(A, C) & ~Trusts(B, A) & ~Trusts(C, B) & (A - B) & (B - C) & (A - C) ) >> Trusts(A, C),
         squared: false,
         weight: weights[15]
      );

      model.add(
         rule: ( Knows(A, B) & Knows(B, A) & Trusts(A, B) ) >> Trusts(B, A),
         squared: false,
         weight: weights[16]
      );
      model.add(
         rule: ( Knows(A, B) & Knows(B, A) & ~Trusts(A, B) ) >> ~Trusts(B, A),
         squared: false,
         weight: weights[17]
      );

      model.add(
         rule: ( Knows(A, B) & Prior(dataStore.getUniqueID(0)) ) >> Trusts(A, B),
         squared: false,
         weight: weights[18]
      );
   }

   @Override
   public void loadData(String dataPath) {
      Inserter inserter = dataStore.getInserter(Knows, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "knows_obs.txt").toString());

      inserter = dataStore.getInserter(Prior, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "prior_obs.txt").toString());

      inserter = dataStore.getInserter(Trusts, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "trusts_obs.txt").toString());

      inserter = dataStore.getInserter(Trusts, targetsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "trusts_target.txt").toString());

      inserter = dataStore.getInserter(Trusts, truthPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "trusts_truth.txt").toString());
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([Knows, Prior]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([Trusts]);
   }

   @Override
   public void eval() {
      continuousEval();
   }
}
