Weight Learning Experiments on the fork of NIPS 2017 workshop paper at nips17-experiment branch.

All of these experiments originated from a core JMLR paper by Stephen Bach.
The code can be found here: https://github.com/stephenbach/bach-jmlr17-code
The paper can be cited as follows:
```
@article{bach:jmlr17,
  Author = {Bach, Stephen H. and Broecheler, Matthias and Huang, Bert and Getoor, Lise},
  Journal = {Journal of Machine Learning Research (JMLR)},
  Title = {Hinge-Loss {M}arkov Random Fields and Probabilistic Soft Logic},
  Year = {2017}
}
```

All experiments should can be run the with respective `run.sh` script in the experiment's directory.
All scripts have been tested on Linux, but should also work fine on Mac.
The run scripts do not explicitly support Windows, but all core components (ie PSL) supports Windows.
Therefore, one can manually follow the steps in the run scripts and translate them to Windows equivalents.

The base requirements for these experiments are:
   - `curl` or `wget` - for fetching data and jars
   - `tar` - for extracting data
   - `java` - to run PSL
   - `ruby` - for various support scripts

Each experiment may include an additional readme file with any additional instructions or notes.
