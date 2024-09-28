import UIKit
import MapKit

struct RecordingData {
    let location: CLLocation
    let date: Date
    let maxDecibel: Float
}

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var recordings: [RecordingData] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        displayAllRecordingsOnMap()
    }
    
    func displayAllRecordingsOnMap() {
        for recording in recordings {
            let annotation = MKPointAnnotation()
            annotation.coordinate = recording.location.coordinate
            annotation.title = "録音日時: \(recording.date)"
            annotation.subtitle = "最大ノイズ: \(recording.maxDecibel) dB"
            mapView.addAnnotation(annotation)
        }

        if let firstRecording = recordings.first {
            let region = MKCoordinateRegion(center: firstRecording.location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }

    // アノテーションビューのカスタマイズ（MKMarkerAnnotationView）
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "RecordingAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true

            // デシベル値に基づくマーカーの色変更
            if let subtitle = annotation.subtitle, let maxDecibel = Float(subtitle?.components(separatedBy: " ")[1] ?? "") {
                if maxDecibel > 115 {
                    annotationView?.markerTintColor = .purple  // 高いデシベルなら赤色
                } else if maxDecibel > 100 {
                    annotationView?.markerTintColor = .red  // 中程度のデシベルならオレンジ色
                } else if maxDecibel > 70 {
                    annotationView?.markerTintColor = .orange  // 中程度のデシベルならオレンジ色
                } else {
                    annotationView?.markerTintColor = .green  // 低いデシベルなら緑色
                }
            }

           
            // Callout用のラベル
            let label = UILabel()
            label.text = "\(annotation.subtitle ?? "") dB"
            annotationView?.detailCalloutAccessoryView = label
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}
