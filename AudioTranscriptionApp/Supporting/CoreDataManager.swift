import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "AudioTranscriptionApp")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }

    func saveTranscription(_ text: String) {
        let context = persistentContainer.viewContext
        let transcription = Transcription(context: context)
        transcription.text = text
        transcription.timestamp = Date()

        do {
            try context.save()
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }

    func fetchTranscriptions() -> [Transcription] {
        let context = persistentContainer.viewContext
        let request: NSFetchRequest<Transcription> = Transcription.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch transcriptions: \(error)")
            return []
        }
    }
}
