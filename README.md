# ARM_analysis
This Repository contains functions to perform association rule mining on microbiome datasets with R scripts designed to be called on the command-line.

## Association Rule Mining (ARM)
Briefly, association rule mining (aka. market basket analysis)  is a method of mining data for associations between elements. In the context of microbial ecology, ARM can be used to find associations between taxa from an array of samples within an experiment. Consider the following feature table:

| id    | s1  | s2  | s3   | s4  | s#   |
|-------|-----|-----|------|-----|------|
| Taxa1 | 0.5 | 0   | .9   | .5  | ...  |
| Taxa2 | 0   | 0   | .001 | .2  | ...  |
| Taxa3 | 0.3 | .4  | .001 | 0   | ...  |
| Taxa# | ... | ... | ...  | ... | .... |

We would like to know if any of the taxa are associated with each other based on their presence in each sample from our dataset.
ARM uses the metrics **support**, **confidence**, and **lift** to determine interesting associations. For instance, maybe we want to know if Taxa1 is associated with Taxa2.
We can define an association rule

**$Taxa1 \rightarrow Taxa2$**

where Taxa1 is termed the *Antecedent* and Taxa2 the *Consequent*. <br />
The association rule is read *"Given Taxa1, how often does Taxa2 occur"*, and support, confidence, and lift are calculated as follows:

$$ Support(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa1,Taxa2)} \over N} $$

$$ Confidence(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa1,Taxa2)} \over Freq(Taxa1)} $$

$$ ExpectedConfidence(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa2)} \over N} $$

$$ Lift(Taxa1 \rightarrow Taxa2) = {{Confidence} \over ExpectedConfidence} $$

When lift is greater than 1 there is a positive association between the Antecedent/s and the Consequent.

## Implementation  
The feature table is converted to presence absence and the proportional metrics are calculated.

| id    | s1  | s2  | s3  | s4  | s#   |
|-------|-----|-----|-----|-----|------|
| Taxa1 | 1   | 0   | 1   | 1   | ...  |
| Taxa2 | 0   | 0   | 1   | 1   | ...  |
| Taxa3 | 1   | 1   | 1   | 0   | ...  |
| Taxa# | ... | ... | ... | ... | .... |

**$Support(Taxa1 \rightarrow Taxa2)$ = 2/4 = 0.5** <br />
**$Confidence(Taxa1 \rightarrow Taxa2)$ = 2/3 = 0.67** <br />
**$ExpectedConfidence(Taxa1 \rightarrow Taxa2)$ = 2/4 = 0.5** <br />
**$Lift(Taxa1 \rightarrow Taxa2)$ = 0.67/0.5 = 1.34**

## Running scripts
First create a conda environment with the appropriate R dependencies with the following code:
```bash
wget https://github.com/ileleiwi/ARM_analysis/blob/main/environment.yml
conda env create -f environment.yml -n ARM_env
```

Clone the ARM_analysis github repository to your computer
```bash
git clone https://github.com/ileleiwi/ARM_analysis
```
Add your feature table to the data directory.<br />
Feature table should be a tsv file with taxa as observations and samples as variables<br />
*Note: set permutations quickly become computationally unwieldy as observation number increases and number of taxa in each set increases (minl and maxl)

Activate conda environment
```bash
conda activate ARM_env
```

Filter feature table to frequent taxa. [filter_to_frequent.R](/scripts/filter_to_frequent.R)
```console
foo@bar:~$ Rscript filter_to_frequent.R --help


Function filters feature table to frequent taxa
	Positional arguments are:
	[1] path to file (tsv)
	[2] threshold (0-1)
Output to file in ../data dir


Execution halted
```
```bash
Rscript filter_to_frequent.R ../data/feature_table.tsv 0.5
```
The above command converts the supplied feature table to present absent format and filters the table to include taxa in at least 50% of the samples. It creates the file `../data/ft_pa_thrshld{threshold}.tsv`

Produce list of taxa sets. [make_sets.R](/scripts/make_sets.R)
```console
foo@bar:~$ Rscript make_sets.R --help


Function creates all possible combinations of id's in id column
	Positional arguments are:
	[1] path to file (tsv)
	[2] id column name
	[3] number of cores
	[4] minimum number of items in set
	[5] maximum number of items in set
	[6] support threshold (0-1)
Output to stdout


Execution halted

```
```bash
Rscript make_sets.R ../data/ft_pa_thrshld0.5.tsv id 10 3 3 0.5 > path_to_sets/sets.txt
```
The above command filters a feature table to a given threshold (taxa must appear in {threshold} proportion of samples). This command can be run without the filter_to_frequent.R preprocessing step if desired. The above command takes the filtered feature table and produces every permutation of individual taxa with each other separated by ";" and outputs to stdout.<br />

example output with minl and maxl set to 3:<br />
a;b;c<br />
a;c;b<br />
b;a;c<br />
b;c;a<br />
c;a;b<br />
c;b;a<br />

Calculate support, confidence, and lift. [calc_metrics.R](/scripts/calc_metrics.R)
```console
foo@bar:~$ Rscript calc_metrics.R --help


Function calculates support, confidence, and lift for ruleset
	Positional arguments are:
	[1] path to file present absent feature table (tsv)
	[2] path to sets file single column tsv of feature combinations
	[3] id column name in feature table
	[4] number of cores
	[5] minimum number of items in set
	[6] maximum number of items in set
	[7] support threshold (0-1)
	[8] outfile name
Output to file in ../data


Execution halted

```
```bash
Rscript calc_metrics.R ../data/ft_pa_thrshld0.5.tsv path_to_sets/sets.txt id 10 3 6 0.5 lift_support_confidence_rules.tsv
```
The above command produces a dataframe named lift_support_confidence_rules.tsv in the data directory. The dataframe includes all rulesets, antacedents, consequents, rule support, rule confidence, rule expected confidence, and rule lift


