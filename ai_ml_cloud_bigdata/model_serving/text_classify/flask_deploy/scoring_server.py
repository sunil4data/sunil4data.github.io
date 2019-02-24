# Create API of ML model using flask

'''
This code takes the JSON data while POST request an performs the prediction using loaded model and returns
the results in JSON format.
'''

# Import libraries
import numpy as np
import codecs, json

import pandas as pd
from logging import FileHandler, WARNING, ERROR

from gensim.models import KeyedVectors
from gensim.parsing.preprocessing import preprocess_string, strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric, remove_stopwords, strip_short

import nltk
nltk.download('punkt')

from sklearn.feature_extraction.text import CountVectorizer

from flask import Flask, request, jsonify
import pickle

app = Flask(__name__)

file_handler = FileHandler('err_log.txt')
file_handler.setLevel(ERROR)
app.logger.addHandler(file_handler)

# Load the model
model = pickle.load(open('classifier_model.pkl','rb'))

df = pd.read_csv('akut.csv')
txt_filters = [lambda x: x.lower(), strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric,
               remove_stopwords, strip_short]

def process_input(row):
    input_merged = row['Assignment Name'] + ' ' + row['School Category']

    # gensim's preprocess_string through series of txt_filters which generates tokens array
    input_processed_tokens = " ".join(preprocess_string(input_merged, txt_filters))

    # input_processed_tokens is deduplicated to form final input string
    # input_processed = " ".join(sorted(set(input_processed_tokens), key=input_processed_tokens.index))
    return input_processed_tokens

vocabulary_to_load = pickle.load(open("vocab.pkl", 'rb'))
count_vect = CountVectorizer(vocabulary=vocabulary_to_load)
load_model = pickle.load(open("classifier_model.pkl", 'rb'))
count_vect._validate_vocabulary()

class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

@app.route('/api',methods=['POST'])
def predict():

    # Get the data from the POST request.
    #data = request.get_json(force=True)
    data = request.json

    #df = pd.DataFrame(data['test_input'])
    #df['processed_input'] = df.apply(lambda row: process_input(row), axis=1)
    #count_vect.fit_transform(df['processed_input'])

    # Make prediction using model loaded from disk as per the data.
    prediction = model.predict(count_vect.transform(data['test_input']))

    # Take the first value of prediction
    #output = prediction[0]
    out_json = json.dumps(prediction, cls=NumpyEncoder)

    return out_json

@app.route('/getback', methods=['POST'])
def getback():
    data = request.json
    return jsonify(data['test_input'])

if __name__ == '__main__':
    app.run(port=5000, debug=True)
