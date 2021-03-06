//
//  LineViewController.swift
//  WVU Mobile
//
//  Created by Kaitlyn Landmesser & Richard Deal on 3/31/15.
//  Copyright (c) 2015 WVUMobile. All rights reserved.
//

import UIKit
import GoogleMaps

class LineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, GMSMapViewDelegate {
    
    var map = GMSMapView()
    var tableView = UITableView()
    
    var line: BusRoute?
    var coords: Dictionary <String, CLLocationCoordinate2D>!
    var selected = -1
    var markerArray = [GMSMarker]()
    
    override func viewDidLoad() {
        title = line?.name
        
        /*
        Set up Google Map View.
        */
        
        map = GMSMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 3))
        map.delegate = self

        let camera = GMSCameraPosition.camera(withLatitude: 39.635582, longitude: -79.954747, zoom: 12)
        map.animate(to: camera)
        
        view.addSubview(map)
        
        
        // Add each stop as Marker
        if let l = line {
            for stop in l.stops {
                let marker = GMSMarker()
                marker.position = coords[stop]!
                marker.title = stop
                marker.map = map
                marker.icon = GMSMarker.markerImage(with: Colors.mountainLineBlue)
                markerArray.append(marker)
            }
        }
        
        // Parse
        let path = Bundle.main.path(forResource: line?.name, ofType: "txt")
        var text = ""
        
        do {
            text = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        } catch {
            print("ugh")
        }
        
        let shape = GMSMutablePath()
        let shapeArray = text.components(separatedBy: "\n")
        for set in shapeArray {
            let c = set.components(separatedBy: "\t")
            shape.add(CLLocationCoordinate2DMake((c[0] as NSString).doubleValue, (c[1] as NSString).doubleValue))
        }
        let polyline = GMSPolyline(path: shape)
        polyline.strokeWidth = 5.0
        polyline.strokeColor = Colors.homeDarkBlue
        polyline.map = map
        
        view.addSubview(map)
        
        let tableView = UITableView(frame: CGRect(x: 0, y: view.frame.height / 3, width: view.frame.width, height: view.frame.height - (view.frame.height / 3) - 103), style: .plain)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        self.view.addSubview(tableView)
        
        twitterButton()
        
        super.viewDidLoad()
    }
    
    func twitterButton() {
        let infoImage = UIImage(named: "Twitter")
        
        let infoView = UIImageView(frame: CGRect(x: 0, y: 0, width: 27, height: 27))
        infoView.image = infoImage
        infoView.image = infoView.image?.withRenderingMode(.alwaysTemplate)
        
        let infoButton = UIButton(frame: (infoView.bounds))
        infoButton.setBackgroundImage(infoView.image, for: .normal)
        infoButton.addTarget(self, action: #selector(LineViewController.loadTwitter), for: .touchUpInside)
        
        let infoButtonItem = UIBarButtonItem(customView: infoButton)
        
        navigationItem.rightBarButtonItem = infoButtonItem
    }
    
    @objc func loadTwitter() {
        let feedPage = WebViewController()
        if let l = line {
            feedPage.data = WebViewData(urlString: "https://twitter.com/\(l.twitter)") 
        }
        navigationController?.pushViewController(feedPage, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return line!.stops.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return UITableViewAutomaticDimension
        }
        else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 25))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 25))
        label.textColor = Colors.homeDarkBlue
        headerView.backgroundColor = Colors.gray
        label.font = UIFont.systemFont(ofSize: 13)
        label.text = line?.runTime
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        
        headerView.addSubview(label)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = line?.hoursString
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight(rawValue: 0.1))
        } else {
            cell.textLabel?.text = line?.stops[indexPath.row - 1]
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight(rawValue: 0.1))
            cell.imageView?.image = UIImage(named: "Stops")?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = Colors.homeDarkBlue
            cell.imageView?.frame = CGRect(x: 0, y: 0, width: cell.frame.height, height: cell.frame.height)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            if selected != indexPath.row - 1 {
                selected = indexPath.row - 1
                if let l = line {
                    let name = l.stops[selected]
                    let camera = GMSCameraPosition(target: coords[name]!, zoom: 16, bearing: 0, viewingAngle: 0)
                    map.animate(to: camera)
                    map.selectedMarker = markerArray[indexPath.row - 1]
                }
            }
            else {
                map.selectedMarker = nil
                let camera = GMSCameraPosition(target: CLLocationCoordinate2DMake(39.635582, -79.954747), zoom: 12, bearing: 0, viewingAngle: 0)
                map.animate(to: camera)
                tableView.cellForRow(at: indexPath)?.isSelected = false
                selected = -1
            }
        }
    }
    
}
