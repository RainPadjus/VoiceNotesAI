from flask import Flask, request, jsonify
import os
from pygpt4all import GPT4All
import whisper

app = Flask(__name__)

# Load the GPT4All model
model_path = 'C:/Users/rando/AppData/Local/nomic.ai/GPT4All/ggml-gpt4all-l13b-snoozy.bin'
gpt4all_model = GPT4All(model_path, prompt_prefix="summary this text:\n\n")

# Load the Whisper model
whisper_model = whisper.load_model("small.en")

# Configure the upload folder
UPLOAD_FOLDER = './uploads'

# Check if the folder exists, create it if it doesn't
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/transcribe', methods=['POST'])
def transcribe():
    audio_data = request.data
    if audio_data:
        audio_file_path = os.path.join(app.config['UPLOAD_FOLDER'], 'temp_audio.wav')
        with open(audio_file_path, 'wb') as f:
            f.write(audio_data)

        result = whisper_model.transcribe(audio_file_path)
        os.remove(audio_file_path)
        return jsonify(result["text"])

    return jsonify({'error': 'No audio data received'}), 400

@app.route('/summarize', methods=['POST'])
def summarize():
    if 'text' not in request.json:
        return jsonify({'error': 'Missing "text" in the request JSON'}), 400

    text = request.json['text']
    print(f"Input text: {text}")  # Debug: print input text

    # Generate summary using GPT4All
    summary = ''
    for token in gpt4all_model.generate(text):
        summary += token

    print(f"Generated summary: {summary}")  # Debug: print generated summary
    return jsonify(summary)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
