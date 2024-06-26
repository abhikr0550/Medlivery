//
//  SearchViewController.swift
//  Medlivery
//
//  Created by Aadesh on 4/5/24.
//

import UIKit
import MapKit

class SearchViewController: UIViewController {
    
    var delegateToMapView: MapViewController!
    
    var mapItems = [MKMapItem]()
    
    let notificationCenter = NotificationCenter.default
    
    let searchBottomSheet = SearchBottomSheet()

    override func loadView() {
        view = searchBottomSheet
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
            self.navigationItem.leftBarButtonItem = backButton
        
        searchBottomSheet.tableViewSearchResults.delegate = self
        searchBottomSheet.tableViewSearchResults.dataSource = self
        searchBottomSheet.searchBar.delegate = self
        
        searchBottomSheet.tableViewSearchResults.separatorStyle = .none
        
        notificationCenter.addObserver(
            self,
            selector: #selector(notificationForPlaces(notification:)),
            name: .placesFromMap,
            object: nil
        )
    }
    
    @objc func notificationForPlaces(notification: Notification){
        mapItems = notification.object as! [MKMapItem]
        self.searchBottomSheet.tableViewSearchResults.reloadData()
    }
    @objc func backButtonTapped() {
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension SearchViewController: UISearchBarDelegate{
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegateToMapView.loadPlacesAroundCurrentLocation()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true)
    }
}
