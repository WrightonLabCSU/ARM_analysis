# ARM_analysis
This Repository contains functions to perform association rule mining on microbiome datasets with R scripts designed to be called on the command-line.

## Association Rule Mining (ARM)
Briefly, association rule mining (aka. market basket analysis)  if a method of mining data for associations between elements. In the context of microbial ecology, ARM can be used to find associations between taxa from an array of samples within an experiment. Consider the following feature table:

| id    | s1  | s2  | s3   | s4  | s#   |
|-------|-----|-----|------|-----|------|
| Taxa1 | 0.5 | 0   | .9   | .5  | ...  |
| Taxa2 | 0   | 0   | .001 | .2  | ...  |
| Taxa3 | 0.3 | .4  | .001 | 0   | ...  |
| Taxa# | ... | ... | ...  | ... | .... |

We would like to know if any of the taxa are associated with each other based on their presence in each sample from our dataset.
ARM uses the metrics support, confidence, and lift to determine interesting associations. For instance, maybe we want to know if Taxa1 is associated with Taxa2.
We can define an association rule

**$Taxa1 \rightarrow Taxa2$**

where Taxa1 is termed the *Antecedent* and Taxa2 the *Consequent*.
The association rule is read *"Given Taxa1, how often does Taxa2 occur"*, and support, confidence, and lift are calculated as follows:

$$ Support(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa1,Taxa2)} \over N} $$

$$ Confidence(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa1,Taxa2)} \over Freq(Taxa1)} $$

$$ ExpectedConfidence(Taxa1 \rightarrow Taxa2) = {{Freq(Taxa2)} \over N} $$

$$ Lift(Taxa1 \rightarrow Taxa2) = {{Confidence} \over ExpectedConfidence} $$

When lift is greater than 1 there is a positive association between the Antecedent/s and the Consequent.

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




