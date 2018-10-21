The goal of this **Coursera Data Science Capstone Final Project** is to build on the work done so far till milestone reporting (refer to http://rpubs.com/sunil4data/milesRepCapstone) and create a web application (Shiny App) for Next Word Prediction.

### Application Workflow

1. Pre-computed LM model containing probabilities of 1,2 & 3-grams is available to Shiny App for serving Next Word Predictions.

2. User enters incomplete sentence of 2 or more words whose next word is to be predicted.

3. Input sentence is cleaned in exact same way as the 'training' data sample was cleaned. NOTE that STOP WORDS are cleaned from 'training' data sample as well as from 'input sentence'.

4. Resulting cleaned input sentence is assumed to contain at least 2 words as we are using upto 3-grams LM model. Extract last 2 tokens (P & Q) from cleaned input sentence.  

5. The goal of prediction is to calculate probability for each of the 1-gram features (Rcandidates) as how probable is it in completing highest n-gram (P_Q_Rcandidates - if seen/observed 3-gram) or backed-off n-grams (Q_Rcandidates, if observed in 2-gram) or ultimately backed-off 1-gram (Rcandidates). Stupid BackOff uses 0.4 as lambda for penalizing backed-off, i.e., lower order n-gram probabilities.


### Results
1. Prediction of 6 most probable completing words & corresponding ngram

2. Cleaned input incomplete sentence

3. Elapsed time