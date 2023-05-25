import whisper

# whisper has multiple models that you can load as per size and requirements
model = whisper.load_model("small.en")

# path to the audio file you want to transcribe
PATH = "test_audio.wav"

result = model.transcribe(PATH)
print(result["text"])