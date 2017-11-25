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

public class PartyAffiliation extends Experiment {
   public PartyAffiliation(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      String[] binaryPredicates = ["Bias", "Boss", "Idol", "Knows", "KnowsWell", "Mentor", "OlderRelative", "Votes"];
      for (String name : binaryPredicates) {
         model.add(
            predicate: name,
            types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
         );
      }
   }

   @Override
   public double[] getDefaultWeights() {
      return [0.50, 0.30, 0.10, 0.05, 0.10, 0.70, 0.80, 0.01];
   }

   @Override
   public void defineRules(double[] weights) {
      int ruleCount = 0;

      model.add(
         rule: ( Bias(A, P) ) >> Votes(A, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & KnowsWell(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & Knows(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & Boss(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & Mentor(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & OlderRelative(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( Votes(A, P) & Idol(B, A) ) >> Votes(B, P),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ~Votes(A, P),
         squared: true,
         weight: weights[ruleCount++]
      );

      model.add(PredicateConstraint.Functional, on : Votes);
   }

   @Override
   public void loadData(String dataPath) {
      Inserter inserter = null;

      inserter = dataStore.getInserter(Bias, obsPartition);
      InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, "bias_obs.txt").toString());

      inserter = dataStore.getInserter(Boss, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "boss_obs.txt").toString());

      inserter = dataStore.getInserter(Idol, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "idol_obs.txt").toString());

      inserter = dataStore.getInserter(Knows, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "knows_obs.txt").toString());

      inserter = dataStore.getInserter(KnowsWell, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "knowswell_obs.txt").toString());

      inserter = dataStore.getInserter(Mentor, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "mentor_obs.txt").toString());

      inserter = dataStore.getInserter(OlderRelative, obsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "olderRelative_obs.txt").toString());

      inserter = dataStore.getInserter(Votes, targetsPartition);
      InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, "votes_targets.txt").toString());
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([Bias, Boss, Idol, Knows, KnowsWell, Mentor, OlderRelative]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([Votes]);
   }

   @Override
   public void eval() {
   }
}
