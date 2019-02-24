import pickle, json
import numpy as np
import pandas as pd
import re

from gensim.models import KeyedVectors
from gensim.parsing.preprocessing import preprocess_string, strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric, remove_stopwords, strip_short

from sklearn.feature_extraction.text import CountVectorizer

from azureml.core.model import Model


def init():
    global model, vocab, txt_filters
    
    txt_filters = [lambda x: x.lower(), strip_tags, strip_punctuation, strip_multiple_whitespaces, strip_numeric, remove_stopwords, strip_short]
    
    model_path = Model.get_model_path(model_name = "classifier_model")
    with open(model_path, "rb") as f_model:
        model = pickle.load(f_model)
        
    vocab_path = Model.get_model_path(model_name = "vocab")
    with open(vocab_path, "rb") as f_vocab:
        vocab = pickle.load(f_vocab)

        
def process_input(row):
    input_merged = row['Assignment Name'] + ' ' + row['School Category']
    
    # gensim's preprocess_string through series of txt_filters which generates tokens array
    input_processed_tokens = " ".join(preprocess_string(input_merged, txt_filters))
    
    return input_processed_tokens


class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return json.JSONEncoder.default(self, obj)

    
def run(raw_data):
    try:
        input_json = json.loads(raw_data)
        
        df = pd.DataFrame.from_dict(input_json, orient='columns')
        df['processed_input'] = df.apply(lambda row: process_input(row), axis=1)
        
        count_vect = CountVectorizer(vocabulary=vocab)
        count_vect._validate_vocabulary()
        
        prediction = model.predict(count_vect.transform(df['processed_input']))
        
        labels_dict = {}
        labels_dict['assignment'] = 0
        labels_dict['quiz'] = 1
        labels_dict['homework'] = 2
        labels_dict['test'] = 3
        labels_dict['extra credit'] = 4

        arr_labels = ['assignment', 'quiz', 'homework', 'test', 'extra credit']

        for index, row in df.iterrows():
            label_match_school_category = re.search('assignment|quiz|homework|test|extra credit', row['School Category'].lower())
            label_match_assignment_name = re.search('assignment|quiz|homework|test|extra credit', row['Assignment Name'].lower()) 
            predicted_match_school_category = re.search(arr_labels[prediction[index]], row['School Category'].lower())
            predicted_match_assignment_name = re.search(arr_labels[prediction[index]], row['Assignment Name'].lower())     
            if label_match_school_category and (label_match_assignment_name is None) and (predicted_match_school_category is None):
                prediction[index] = labels_dict[label_match_school_category.group()]
            elif label_match_assignment_name and (label_match_school_category is None) and (predicted_match_assignment_name is None):
                prediction[index] = labels_dict[label_match_assignment_name.group()]
        
        out_json = json.dumps(prediction, cls=NumpyEncoder)
        return out_json
    
    except Exception as e:
        msg_exception = str(e)
        return json.dumps({"error": msg_exception})
