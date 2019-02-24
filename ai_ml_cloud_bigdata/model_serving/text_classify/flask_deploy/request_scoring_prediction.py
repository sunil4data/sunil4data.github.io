import requests

# URL
url = 'http://localhost:5000/api'

# Change the value of experience that you want to test
r = requests.post(url,json={'test_input': ["button button project default category", "button button quiz default category", "good man quiz default category", "stargazing comp questions writing essay", "story hour creative piece default category"]})
print(r.json())
