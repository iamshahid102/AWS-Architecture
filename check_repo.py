import json
import urllib.request

url = "https://api.github.com/repos/iamshahid102/AWS-Architecture/contents"
with urllib.request.urlopen(url) as response:
    data = json.load(response)
    for item in data:
        print(f'{item["name"]} ({item["type"]})')