import UIKit
import AVFoundation
import CoreData

class HomeController: UIViewController {

    private let transcriptionView = TranscriptionView()
    private let transcriptionService = TranscriptionService()
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var audioFileURL: URL?
    private var transcriptions: [Transcription] = []

    override func loadView() {
        view = transcriptionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        transcriptionView.recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        transcriptionView.historyTableView.dataSource = self
        transcriptionView.historyTableView.delegate = self

        // Register custom cell
        transcriptionView.historyTableView.register(TranscriptionCell.self, forCellReuseIdentifier: "TranscriptionCell")

        // Load from Core Data
        transcriptions = CoreDataManager.shared.fetchTranscriptions()
    }

    @objc private func recordTapped() {
        if isRecording {
            stopRecording()
            transcriptionView.recordButton.setTitle("Start Recording", for: .normal)
        } else {
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    guard granted else {
                        print("Microphone permission denied.")
                        return
                    }
                    DispatchQueue.main.async {
                        self?.startRecording()
                        self?.transcriptionView.recordButton.setTitle("Stop Recording", for: .normal)
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                    guard granted else {
                        print("Microphone permission denied.")
                        return
                    }
                    DispatchQueue.main.async {
                        self?.startRecording()
                        self?.transcriptionView.recordButton.setTitle("Stop Recording", for: .normal)
                    }
                }
            }
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let filename = UUID().uuidString + ".m4a"
            let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            audioFileURL = path

            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.record()
            isRecording = true
            print("Recording started: \(path)")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        print("Recording stopped")
        if let fileURL = audioFileURL {
            transcribeAudio(at: fileURL)
        }
    }

    private func transcribeAudio(at url: URL) {
        transcriptionView.loadingIndicator.startAnimating()

        transcriptionService.sendAudio(audioURL: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.transcriptionView.loadingIndicator.stopAnimating()

                switch result {
                case .success(let transcriptionText):
                    // Save to Core Data
                    CoreDataManager.shared.saveTranscription(transcriptionText)
                    // Reload from Core Data
                    self.transcriptions = CoreDataManager.shared.fetchTranscriptions()
                    self.transcriptionView.historyTableView.reloadData()

                    // Scroll to latest
                    let indexPath = IndexPath(row: self.transcriptions.count - 1, section: 0)
                    self.transcriptionView.historyTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)

                case .failure(let error):
                    print("Transcription failed: \(error)")
                    // Optional: show error as a row
                    CoreDataManager.shared.saveTranscription("Error: \(error.localizedDescription)")
                    self.transcriptions = CoreDataManager.shared.fetchTranscriptions()
                    self.transcriptionView.historyTableView.reloadData()
                }
            }
        }
    }
}

extension HomeController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transcriptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TranscriptionCell", for: indexPath) as? TranscriptionCell else {
            return UITableViewCell()
        }
        let transcription = transcriptions[indexPath.row]

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short

        if let date = transcription.timestamp {
            cell.timestampLabel.text = formatter.string(from: date)
        } else {
            cell.timestampLabel.text = ""
        }

        cell.transcriptionLabel.text = transcription.text ?? "No transcription"

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        transcriptionView.historyTableView.deselectRow(at: indexPath, animated: true)
    }
}
