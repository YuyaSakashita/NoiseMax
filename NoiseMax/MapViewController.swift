import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var recordedLocation: CLLocation?
    var maxDecibel: Float = 0.0
    var recordingDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = recordedLocation {
            displayLocationOnMap(location: location)
        }
    }
    
    func displayLocationOnMap(location: CLLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        annotation.title = "録音日時: \(recordingDate!)"
        annotation.subtitle = "最大ノイズ: \(maxDecibel) dB"
        mapView.addAnnotation(annotation)
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
}
