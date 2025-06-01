from flask import Flask, request, jsonify
import whisper
import tempfile
import ssl
ssl._create_default_https_context = ssl._create_unverified_context


app = Flask(__name__)
model = whisper.load_model("base")

@app.route("/transcribe", methods=["POST"])
def transcribe():
    if "audio" not in request.files:
        return jsonify({"error": "No audio file provided"}), 400

    audio = request.files["audio"]
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        audio.save(tmp.name)
        result = model.transcribe(tmp.name)
        return jsonify({"transcription": result["text"]})

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
