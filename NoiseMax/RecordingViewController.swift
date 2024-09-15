import UIKit
import AVFoundation
import CoreLocation

class RecordingViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var measureButton: UIButton!
    
    var audioRecorder: AVAudioRecorder!
    var maxDecibel: Float = 0.0
    let locationManager = CLLocationManager()
    var recordedLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapView" {
            // 目的のビューコントローラ（MapViewController）にデータを渡す
            let mapViewController = segue.destination as! MapViewController
            mapViewController.recordedLocation = recordedLocation // 取得した位置情報
            mapViewController.maxDecibel = maxDecibel // 計測された最大dB値
            mapViewController.recordingDate = Date() // 現在の日時
        }
    }
    
    func setupUI() {
        statusLabel.text = "ノイズを計測"
        circleView.layer.cornerRadius = circleView.frame.size.width / 2
        measureButton.setTitle("計測する", for: .normal)
    }

    @IBAction func startMeasuring(_ sender: UIButton) {
        statusLabel.text = "計測中"
        measureButton.isEnabled = false
        startRecording()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.stopRecording()
            self.statusLabel.text = "計測終了"
            self.maxDecibel = self.calculateMaxDecibel()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.statusLabel.text = "最大ノイズ"
                self.displayMaxDecibel()
            }
        }
    }
    
    func startRecording() {
        // 録音の設定
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
        
        // 位置情報を取得
        locationManager.startUpdatingLocation()
    }
    
    func stopRecording() {
        audioRecorder.stop()
        locationManager.stopUpdatingLocation()
    }
    
    func calculateMaxDecibel() -> Float {
        audioRecorder.updateMeters()
        let decibel = audioRecorder.averagePower(forChannel: 0)
        return max(maxDecibel, decibel)
    }
    
    func displayMaxDecibel() {
        let maxDecibelText = String(format: "%.2f dB", maxDecibel)
        let alert = UIAlertController(title: "最大ノイズ", message: maxDecibelText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func getAudioFileURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = paths[0].appendingPathComponent("recording.m4a")
        return filePath
    }
    
    // 位置情報取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        recordedLocation = locations.last
    }
}
