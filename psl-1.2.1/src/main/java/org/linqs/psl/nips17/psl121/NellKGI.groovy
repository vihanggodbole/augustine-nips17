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

public class NellKGI extends Experiment {
   public NellKGI(ConfigBundle config, DataStore dataStore) {
      super(config, dataStore);
      // HACK(eriq): For stupid Groovy reasons, we have to construct the model here.
      model = new PSLModel(this, dataStore);
   }

   @Override
   public void definePredicates() {
      String[] binaryPredicates = ["Sub", "RSub", "Mut", "RMut", "Inv", "Domain", "Range2", "SameEntity", "ValCat", "TrCat", "CandCat", "CandCat_General", "CandCat_CBL", "CandCat_CMC", "CandCat_CPL", "CandCat_Morph", "CandCat_SEAL", "PromCat_General", "Cat"];
      for (String name : binaryPredicates) {
         model.add(
            predicate: name,
            types: [ArgumentType.UniqueID, ArgumentType.UniqueID]
         );
      }

      String[] ternaryPredicates = ["ValRel", "TrRel", "CandRel", "CandRel_General", "CandRel_CBL", "CandRel_CPL", "CandRel_SEAL", "PromRel_General", "Rel"];
      for (String name : ternaryPredicates) {
         model.add(
            predicate: name,
            types: [ArgumentType.UniqueID, ArgumentType.UniqueID, ArgumentType.UniqueID]
         );
      }
   }

   @Override
   public double[] getDefaultWeights() {
      return [
         0025.0, 0025.0, 0025.0, 0100.0, 0100.0, 0100.0, 0100.0, 0100.0, 0100.0,
         0100.0, 0001.0, 0001.0, 0001.0, 0001.0, 0001.0, 0001.0,
         0001.0, 0001.0, 0001.0, 0001.0, 0001.0, 0001.0, 0001.0,
         0001.0, 0002.0, 0002.0, 0001.0, 0001.0
      ];
   }

   @Override
   public void defineRules(double[] weights) {
      int ruleCount = 0;

      model.add(
         rule: ( VALCAT(B, C) & SAMEENTITY(A, B) & CAT(A, C) ) >> CAT(B, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(B, Z, R) & SAMEENTITY(A, B) & REL(A, Z, R) ) >> REL(B, Z, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(Z, B, R) & SAMEENTITY(A, B) & REL(Z, A, R) ) >> REL(Z, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, D) & SUB(C, D) & CAT(A, C) ) >> CAT(A, D),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, S) & RSUB(R, S) & REL(A, B, R) ) >> REL(A, B, S),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, D) & MUT(C, D) & CAT(A, C) ) >> ~CAT(A, D),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, S) & RMUT(R, S) & REL(A, B, R) ) >> ~REL(A, B, S),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(B, A, S) & INV(R, S) & REL(A, B, R) ) >> REL(B, A, S),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & DOMAIN(R, C) & REL(A, B, R) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(B, C) & RANGE2(R, C) & REL(A, B, R) ) >> CAT(B, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & CANDREL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_GENERAL(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & CANDREL_GENERAL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_CBL(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & CANDREL_CBL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_CMC(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_CPL(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & CANDREL_CPL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_MORPH(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & CANDCAT_SEAL(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & CANDREL_SEAL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) & PROMCAT_GENERAL(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) & PROMREL_GENERAL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) ) >> ~CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) ) >> ~REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALCAT(A, C) ) >> CAT(A, C),
         squared: true,
         weight: weights[ruleCount++]
      );
      model.add(
         rule: ( VALREL(A, B, R) ) >> REL(A, B, R),
         squared: true,
         weight: weights[ruleCount++]
      );
   }

   @Override
   public void loadData(String dataPath) {
      Inserter inserter = null;

      for (StandardPredicate predicate : getClosedPredicates()) {
         inserter = dataStore.getInserter(predicate, obsPartition);
         InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, predicate.getName() + "_obs.txt").toString());
      }

      for (StandardPredicate predicate : getOpenPredicates()) {
         inserter = dataStore.getInserter(predicate, obsPartition);
         InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, predicate.getName() + "_obs.txt").toString());

         inserter = dataStore.getInserter(predicate, targetsPartition);
         InserterUtils.loadDelimitedData(inserter, Paths.get(dataPath, predicate.getName() + "_targets.txt").toString());

         inserter = dataStore.getInserter(predicate, truthPartition);
         InserterUtils.loadDelimitedDataTruth(inserter, Paths.get(dataPath, predicate.getName() + "_truth.txt").toString());
      }
   }

   @Override
   protected Set<StandardPredicate> getClosedPredicates() {
      return new HashSet<StandardPredicate>([
            Sub, RSub, Mut, RMut, Inv, Domain, Range2, SameEntity, ValCat,
            TrCat, CandCat, CandCat_General, CandCat_CBL, CandCat_CMC,
            CandCat_CPL, CandCat_Morph, CandCat_SEAL, PromCat_General,
            ValRel, TrRel, CandRel, CandRel_General, CandRel_CBL,
            CandRel_CPL, CandRel_SEAL, PromRel_General
         ]);
   }

   @Override
   protected Set<StandardPredicate> getOpenPredicates() {
      return new HashSet<StandardPredicate>([Cat, Rel]);
   }

   @Override
   public void eval() {
      continuousEval();
      discreteEval(0.5);
   }
}
