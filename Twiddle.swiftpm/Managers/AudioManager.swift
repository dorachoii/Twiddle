import SwiftUI
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    var audioPlayer: AVAudioPlayer?
    
    func playSound(named soundFileName: String) {
        if let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("MP3 파일을 재생할 수 없습니다: \(error.localizedDescription)")
            }
        } else {
            print("파일을 찾을 수 없습니다: \(soundFileName).mp3")
        }
    }
    
    func stopSound() {
        audioPlayer?.stop()
    }
}
