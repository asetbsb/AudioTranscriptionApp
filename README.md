# 🎙️ AudioTranscriptionApp

An iOS application that records user speech and transcribes it using a custom Flask API powered by OpenAI's Whisper model.

## 🛠 Tech Stack

- **Frontend (iOS)**
  - Swift, UIKit
  - AVFoundation for audio recording
  - Core Data for local storage of transcriptions
  - URLSession + URLRequest for API networking (multipart/form-data)
  - MVC architecture

- **Backend (Python)**
  - Flask REST API
  - Whisper (OpenAI) model for speech-to-text
  - Handles audio uploads and returns transcription in JSON format

## 📱 Features

- Tap to start/stop recording with real-time UI feedback  
- Audio is saved and sent as `.m4a` to the backend  
- Transcriptions are saved locally and displayed in a history table  
- Smooth error handling and persistent data via Core Data

