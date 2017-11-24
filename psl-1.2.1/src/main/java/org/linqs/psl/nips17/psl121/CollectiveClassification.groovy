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

public class CollectiveClassification extends Experiment {
   public CollectiveClassification(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      model.add(
         predicate: "Link",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );

      model.add(
         predicate: "HasCat",
         types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
      );
   }

   @Override
   public double[] getDefaultWeights() {
      return [1.0, 1.0, 0.01];
   }

   @Override
   public void defineRules(double[] weights) {
      model.add(
         rule: ( HasCat(A, C) & Link(A, B) & (A - B) ) >> HasCat(B, C),
         squared: true,
         weight: weights[0]
      );

      model.add(
         rule: ( HasCat(A, C) & Link(B, A) & (A - B) ) >> HasCat(B, C),
         squared: true,
         weight: weights[1]
      );

      model.add(
         rule: ~HasCat(A, N),
         squared: true,
         weight: weights[2]
      );

      model.add(PredicateConstraint.Functional, on : HasCat);
   }

   @Override
   public void loadData(String dataPath) {
      Inserter inserter = dataStore.getInserter(Link, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "link_obs.txt").toString());

      inserter = dataStore.getInserter(HasCat, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "hasCat_obs.txt").toString());

      inserter = dataStore.getInserter(HasCat, targetsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "hasCat_targets.txt").toString());

      inserter = dataStore.getInserter(HasCat, truthPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "hasCat_truth.txt").toString());
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([Link]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([HasCat]);
   }

   @Override
   public void eval() {
      discreteEval(0.5);
   }
}
