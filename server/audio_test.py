import requests

API_URL = "http://127.0.0.1:5000/speech_to_text"

def speech_to_text_query(audio_file_path):
    with open(audio_file_path, 'rb') as audio_file:
        response = requests.post(API_URL, files={'file': audio_file})
    return response.json()

audio_file_path = "path/to/your/audio/file.wav"

try:
    output = speech_to_text_query(audio_file_path)
    print(output)
except Exception as e:
    print(f"Error: {e}")
