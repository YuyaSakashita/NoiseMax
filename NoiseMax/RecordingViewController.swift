import UIKit
import AVFoundation
import CoreLocation

class RecordingViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var measureButton: UIButton!
    @IBOutlet weak var decibelLabel: UILabel!  // dBを表示するためのUILabel
    
    var audioRecorder: AVAudioRecorder!
    var maxDecibel: Float = 0.0
    let locationManager = CLLocationManager()
    var recordedLocation: CLLocation?
    var levelTimer: Timer?
    
    let highestRecordKey = "HighestRecord" // UserDefaultsキー

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestMicrophonePermission() // マイクの権限リクエスト
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func setupUI() {
        statusLabel.text = "ノイズを計測"
        circleView.layer.cornerRadius = circleView.frame.size.width / 2
        circleView.backgroundColor = UIColor.white // 初期状態は白
        measureButton.setTitle("計測する", for: .normal)
        
        // 初期状態のdBラベル
        decibelLabel.text = "0 dB"
    }
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("マイクへのアクセスが許可されました")
            } else {
                print("マイクへのアクセスが拒否されました")
            }
        }
    }

    @IBAction func startMeasuring(_ sender: UIButton) {
        statusLabel.text = "計測中"
        measureButton.isEnabled = false
        startRecording()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.stopRecording()
            self.statusLabel.text = "計測終了"
            self.checkNewRecord() // 新記録の確認
            
            // 録音後に最大デシベルを表示
            let finalMaxDecibel = self.calculateMaxDecibel()
            self.displayMaxDecibel(finalMaxDecibel) // 録音後の最大デシベルを表示
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.measureButton.isEnabled = true // 再度計測可能に
                self.circleView.backgroundColor = UIColor.white // 録音終了後は白
                self.decibelLabel.text = "0 dB"  // 録音終了後は0に戻す
            }
        }
    }
    
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let audioFileName = getAudioFileURL()
        audioRecorder = try? AVAudioRecorder(url: audioFileName, settings: settings)
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        
        // 最大デシベルを初期化
        maxDecibel = -120 // 初期値を最小値に設定
        
        locationManager.startUpdatingLocation()
        
        // 録音開始時に音量をチェックするタイマーを開始
        levelTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateAudioLevel), userInfo: nil, repeats: true)
    }
    
    func stopRecording() {
        audioRecorder.stop()
        locationManager.stopUpdatingLocation()
        
        // タイマーを停止し、色を白に戻す
        levelTimer?.invalidate()
        circleView.backgroundColor = UIColor.white
    }
    
    func calculateMaxDecibel() -> Float {
        audioRecorder.updateMeters()
        let decibel = audioRecorder.peakPower(forChannel: 0) + 120 // -120を0に合わせる
        maxDecibel = max(maxDecibel, decibel) // 最大値を更新
        return maxDecibel
    }
    
    func displayMaxDecibel(_ maxDecibel: Float) {
        let maxDecibelText = String(format: "%.2f dB", maxDecibel)
        let alert = UIAlertController(title: "最大ノイズ", message: maxDecibelText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func getAudioFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("recording.m4a")
    }
    
    @objc func updateAudioLevel() {
        audioRecorder.updateMeters()
        let decibel = audioRecorder.averagePower(forChannel: 0) + 120 // -120を0に合わせる
        updateCircleColor(for: decibel)
        updateDecibelLabel(for: decibel)  // dBラベルを更新
        _ = calculateMaxDecibel() // 最大デシベルを計算して更新
    }
    
    func updateCircleColor(for decibel: Float) {
        switch decibel {
        case ..<80:
            circleView.backgroundColor = UIColor.green
        case 80..<100:
            circleView.backgroundColor = UIColor.yellow
        case 100..<115:
            circleView.backgroundColor = UIColor.red
        case 115...:
            circleView.backgroundColor = UIColor.purple
        default:
            circleView.backgroundColor = UIColor.white
        }
    }
    
    // リアルタイムでdB値をUILabelに表示
    func updateDecibelLabel(for decibel: Float) {
        let decibelText = String(format: "%.2f dB", decibel)
        decibelLabel.text = decibelText
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        recordedLocation = locations.last
    }
    
    // 新記録の確認と表示
    func checkNewRecord() {
        let currentRecord = UserDefaults.standard.float(forKey: highestRecordKey)
        
        if maxDecibel > currentRecord {
            UserDefaults.standard.set(maxDecibel, forKey: highestRecordKey)
            displayNewRecordAlert()
        }
    }
    
    // 新記録アラートを表示
    func displayNewRecordAlert() {
        let alert = UIAlertController(title: "New Record!", message: "あなたの新しい最高記録: \(String(format: "%.2f", maxDecibel)) dB", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
