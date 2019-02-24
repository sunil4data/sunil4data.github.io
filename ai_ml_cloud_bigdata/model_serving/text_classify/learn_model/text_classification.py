import numpy as np
import pandas as pd

from gensim.models import KeyedVectors
from gensim.parsing.preprocessing import preprocess_string, strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric, remove_stopwords, strip_short

import nltk
nltk.download('punkt')
from nltk.tokenize import word_tokenize

from tqdm import tqdm
tqdm.pandas()

from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.naive_bayes import MultinomialNB

import pickle
import requests
import json


#
# Read training dataset
#
df = pd.read_csv('akut.csv')

#
# Pre-process
#
txt_filters = [lambda x: x.lower(), strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric, remove_stopwords, strip_short]

def process_input(row):
    input_merged = row['Assignment Name'] + ' ' + row['School Category']
    
    # gensim's preprocess_string through series of txt_filters which generates tokens array
    input_processed_tokens = " ".join(preprocess_string(input_merged, txt_filters))
    
    # input_processed_tokens is deduplicated to form final input string
    #input_processed = " ".join(sorted(set(input_processed_tokens), key=input_processed_tokens.index))
    return input_processed_tokens
    
df['processed_input'] = df.apply(lambda row: process_input(row), axis=1)

#
# Learn MultiNB classifier model
#
df['label'] = pd.factorize(df['Derived Generic Category'])[0]

X_train, X_test, y_train, y_test = train_test_split(df['processed_input'], df['label'], test_size=0.1)
count_vect = CountVectorizer()
X_train_counts = count_vect.fit_transform(X_train)
pickle.dump(count_vect.vocabulary_, open('vocab.pkl','wb'))

clf = MultinomialNB().fit(X_train_counts, y_train)

#
# Saving model to disk
#
pickle.dump(clf, open('classifier_model.pkl','wb'))

#
# Sample prediction
#
test_inputs = ["button button project default category", "button button quiz default category", "good man quiz default category", "stargazing comp questions writing essay", "story hour creative piece default category"]
df_test_inputs = pd.DataFrame(test_inputs)
predicted_label = clf.predict(count_vect.transform(df['processed_input']))

#
# Print FAILED prediction
#
for i in range(0, df.shape[0]):
    if predicted_label[i] != df['label'][i]:
        print(i, predicted_label[i], df['processed_input'][i], df['label'][i])

score_truth = (predicted_label == df['label'].values)
print(score_truth.sum())