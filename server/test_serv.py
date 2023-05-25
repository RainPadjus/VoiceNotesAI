import requests

API_URL_SUMMARIZE = "http://127.0.0.1:5000/summarize"

def query_summarize(payload):
    response = requests.post(API_URL_SUMMARIZE, json=payload)
    return response.json()

# Test the text summarization endpoint
payload = {
    "text": "Are you a front-end engineer looking to improve your JavaScript skills? Or perhaps you're a non-front-end engineer looking to learn JavaScript? Then the 30 Days LeetCode Challenge is just for...",
}

try:
    output = query_summarize(payload)
    print("Text summarization output:", output)
except Exception as e:
    print(f"Error: {e}")
