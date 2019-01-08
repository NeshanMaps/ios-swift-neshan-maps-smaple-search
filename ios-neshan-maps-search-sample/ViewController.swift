//
//  ViewController.swift
//  ios-neshan-maps-search-sample
//
//  Created by M.Madadi on 12/23/18.
//  Copyright © 2018 Rajman. All rights reserved.
//

import UIKit
import AFNetworking

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // layer number in which map is added
    let BASE_MAP_INDEX: Int32 = 0
    
    // map UI element
    @IBOutlet var map: NTMapView!
    // You can add some elements to a VectorElementLayer
    var markerLayer = NTVectorElementLayer()
    // Marker that will be added on map
    var marker = NTMarker()
    // an id for each marker
    var markerId: Double = 0
    // marker animation style
    var animSt = NTAnimationStyle()
    
    // Array for saving Title, Address and Location Result from NeshanSearchAPI
    var finalTitleResult: [String] = []
    var finalAddressResult: [String] = []
    var finalLocationResult: [[Double]] = [[]]
    
    // Table of search result
    @IBOutlet weak var table: UITableView!
    // TextField for search
    @IBOutlet weak var txtSearch: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Call for Initializing map
        initMap()
    }
    
    // MARK: - Initializing Map
    func initMap() {
        // Creating a VectorElementLayer (called markerLayer) to add all markers ti it and adding it to map's layers
        markerLayer = NTNeshanServices.createVectorElementLayer()
        map?.getLayers()?.add(markerLayer)
        
        // add STANDARD_DAY map to layer BASE_MAP_INDEX
        map?.getOptions()?.setZoom(NTRange(min: 4.5, max: 18))
        let baseMap: NTLayer = NTNeshanServices.createBaseMap(NTNeshanMapStyle.STANDARD_DAY)
        map?.getLayers()?.insert(BASE_MAP_INDEX, layer: baseMap)
        
        // Setting map focal positionto a fixed position and setting camera zoom
        map?.setFocalPointPosition(NTLngLat(x: 51.330743, y: 35.767234), durationSeconds: 0.5)
        map?.setZoom(14, durationSeconds: 0.5)
        view = map
    }

    // MARK: - AddMarker
    func addMarker(loc: NTLngLat) {
        // If you want to have only one marker on map at a time, uncomment next line to delete all markers before adding a new marker
        // markerLayer.clear()
        
        // Creating animation for marker. We should use an object of type AnimationStyleBuilder, set
        // all animation features on it and then call buildStyle() method that returns an object of type
        // AnimationStyle
        let animStB1 = NTAnimationStyleBuilder()
        animStB1?.setFade(NTAnimationType.ANIMATION_TYPE_SMOOTHSTEP)
        animStB1?.setSizeAnimationType(NTAnimationType.ANIMATION_TYPE_SPRING)
        animStB1?.setPhaseInDuration(0.5)
        animStB1?.setPhaseOutDuration(0.5)
        animSt = animStB1!.buildStyle()
        
        // Creating marker style. We should use an object of type MarkerStyleCreator, set all features on it
        // and then call buildStyle method on it. This method returns an object of type MarkerStyle
        let markStCr = NTMarkerStyleCreator()
        markStCr?.setSize(30)
        markStCr?.setBitmap(NTBitmapUtils.createBitmap(from: UIImage(named: "ic_marker")))
        // AnimationStyle object - that was created before - is used here
        markStCr?.setAnimationStyle(animSt)
        var markSt = NTMarkerStyle()
        markSt = markStCr!.buildStyle()
        
        // Creating marker
        marker = NTMarker(pos: loc, style: markSt)
        // Adding marker to markerLayer, or showing marker on map!
        markerLayer.add(marker)
    }

    // MARK: - NeshanSearchAPI
    private func neshanSearchAPI(_ loc: NTLngLat, _ term: String) {
        // Defult URL configuration
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        // Using AFNetwork cocoapods library
        let manager = AFURLSessionManager(sessionConfiguration: configuration)
        
        // Create the url that we want request to it
        let requestURL: String = String(format: "https://api.neshan.org/v1/search?term=%@&lat=%f&lng=%f", term, loc.getY(), loc.getX())
        
        // Encoding url fo persian text inside it
        let requestUrlEncoded = requestURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        // Create a request with that url and setting your API_KEY inside header
        let url: URL = URL(string: requestUrlEncoded!)!
        var request: URLRequest = URLRequest(url: url)
        request.setValue(API_KEY, forHTTPHeaderField: "Api-Key")
        
        // URLSessionDataTask
        let dataTask: URLSessionDataTask = manager.dataTask(with: request, uploadProgress: nil, downloadProgress: nil) { (response: URLResponse, responseObject: Any?, error: Error?) in
            // Get and check response from server
            if let responseObj = responseObject as? [String:Any] {
                if let count = responseObj["count"] as? Int {
                    if count == 0 {
                        // No result found
                        DispatchQueue.main.async {
                            self.table.reloadData()
                            self.table.isHidden = true
                        }
                        print("Place Not Found")
                    } else {
                        // get Title, Address, Location of response
                        if let itemsArray = responseObj["items"] as? [Any] {
                            for i in 0...(itemsArray.count - 1) {
                                if let items = itemsArray[i] as? [String:Any] {
                                    // Append each Title, Address and Location to its finalArray
                                    if let title = items["title"] as? String, let address = items["address"] as? String, let locationArray = items["location"] as? [String:Any] {
                                        
                                        if let locationX = locationArray["x"] as? Double, let locationY = locationArray["y"] as? Double {
                                            self.finalLocationResult.append([locationX, locationY])
                                        }
                                        
                                        self.finalTitleResult.append(title)
                                        self.finalAddressResult.append(address)
                                        
                                    }
                                }
                            }
                            // Reload data of TableView
                            DispatchQueue.main.async {
                                self.table.reloadData()
                                self.table.isHidden = false
                            }
                        }
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    // numberOfRowsInSection function for number of table section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return finalTitleResult.count
    }
    
    // cellForRowAt function for creating each cell action
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Define a title and address for each cell
        var title = String()
        var address = String()
        // Each cell give its own title and address from finalArray
        title = finalTitleResult[indexPath.row]
        address = finalAddressResult[indexPath.row]
        
        // Contact tableView and its cell Class (SearchViewCell)
        let reuseIdentifier = "SearchViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! SearchViewCell
        // setSearchResult function for setting result Title and Address to cell
        cell.setSearchResult(title: title, address: address)
        // Returning cell
        return cell
    }
    
    // didSelectRowAt function for touching each cell action
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Hide table and empty serach textField and dissmiss keyboard
        txtSearch.text = ""
        self.table.isHidden = true
        dissmissKeyboard()
        // Move camera to that touched cell location and create a marker
        let destination = NTLngLat(x: finalLocationResult[indexPath.row][0], y: finalLocationResult[indexPath.row][1])
        map.setFocalPointPosition(destination, durationSeconds: 0.5)
        addMarker(loc: destination!)
    }
    
    // Reaction for changing search TextField value
    @IBAction func editingChanged(_ sender: UITextField) {
        // First we need to remove all previuos result for setting new result to arrays
        self.finalTitleResult.removeAll()
        self.finalAddressResult.removeAll()
        self.finalLocationResult.removeAll()
        // If user delete all charachter in textField we hide the result table
        if sender.text == "" {
            DispatchQueue.main.async {
                self.table.isHidden = true
            }
        } else {
            // We use a short delay for better performance of searching
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // After 0.75 seconds that user changed the value of search textField we call neshanSearchAPI and get Search Result
                self.neshanSearchAPI(self.map.getFocalPointPosition(), sender.text!)
            }
        }
    }
    
    // Close button clear textField and hide table
    @IBAction func btnCloseKeyboard(_ sender: UIButton) {
        dissmissKeyboard()
        self.table.isHidden = true
    }
    
    // dissmissKeyboard
    private func dissmissKeyboard() {
        view.endEditing(true)
    }
    
}

