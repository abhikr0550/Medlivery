//
//  CreateOrderController.swift
//  Medlivery
//
//  Created by Abhishek Kumar on 4/5/24.
//

import UIKit
//MARK: importing the library to use PHPicker...
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class CreateOrderController: UIViewController {
    
    var currentUser:FirebaseAuth.User?
    let createOrderView = CreateOrderView()
    var delegate:ViewController!
    var pickedImage:UIImage!
    var orderNumber = 1
    let database = Firestore.firestore()
    let childProgressView = ProgressSpinnerViewController()
    let storage = Storage.storage()
    var storedProfilePhotoURL:URL?
    var storeName: String?
    var storeAddressLine1: String?
    var storeAddressLine2: String?
    var storeAddressCity: String?
    var storeAddressState: String?
    var storeAddressZip: String?
    var storeAddressCountry: String?
    
    override func loadView() {
        view = createOrderView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        orderNumber = 1
        
        createOrderView.buttonUploadPrescription.menu = getMenuImagePicker()
        
        createOrderView.buttonCreateOrder.addTarget(self, action: #selector(onAddOrderButtonTapped), for: .touchUpInside)
        
        createOrderView.navigationButton.addTarget(self, action: #selector(onNavigationButtonTapped), for: .touchUpInside)
        
    }
    
    @objc func onNavigationButtonTapped(){
        let mapViewController = MapViewController();
        mapViewController.createOrder = self
        self.navigationController?.pushViewController(mapViewController, animated: true);
    }
    
    func setPlaceName() {
        createOrderView.textFieldLocation.text = self.storeName
    }
    
    func getMenuImagePicker() -> UIMenu{
        let menuItems = [
            UIAction(title: "Camera",handler: {(_) in
                self.pickUsingCamera()
            }),
            UIAction(title: "Gallery",handler: {(_) in
                self.pickPhotoFromGallery()
            })
        ]
        
        return UIMenu(title: "Select source", children: menuItems)
    }
    
    //MARK: take Photo using Camera...
    func pickUsingCamera(){
        let cameraController = UIImagePickerController()
        cameraController.sourceType = .camera
        cameraController.allowsEditing = true
        cameraController.delegate = self
        present(cameraController, animated: true)
    }

    //MARK: pick Photo using Gallery...
    func pickPhotoFromGallery(){
        var configuration = PHPickerConfiguration()
        configuration.filter = PHPickerFilter.any(of: [.images])
        configuration.selectionLimit = 1
        
        let photoPicker = PHPickerViewController(configuration: configuration)
        
        photoPicker.delegate = self
        present(photoPicker, animated: true, completion: nil)
    }
    
    @objc func onAddOrderButtonTapped(){
        
        // Check for empty fields
        guard let location = createOrderView.textFieldLocation.text?.trimmingCharacters(in: .whitespacesAndNewlines), !location.isEmpty else {
                // Display an alert for empty fields
                showAlert(title: "Empty Fields", message: "Please fill in all the fields.")
                return
        }
        
        if(createOrderView.textFieldLocation.text == "Select Location"){
            showAlert(title: "Location not selected", message: "You have to select a location to place an order")
            return
        }
        
        if(pickedImage == nil){
            showAlert(title: "Prescription missing", message: "You have to upload a prescription to place an order")
            return
        }
        
        let orderName = "Order"
        
        let orderString = "\(orderName)_\(self.orderNumber)"
        print(orderString) // Output: Order_1

        // Increase order number
        orderNumber += 1
        let individualOrder = IndividualOrder(name : orderString, location: location, image: pickedImage ?? (UIImage(systemName: "photo"))!)
        
        uploadProfilePhotoToStorage(individualOrder: individualOrder)
    }
    
    func addOrderToFireStore(individualOrder: IndividualOrder) {
        guard let userEmail = currentUser?.email else {
            return
        }
        
        let collectionOrders = database.collection("users").document(userEmail).collection("orders")
        let storeAddress = "\(self.storeAddressLine1 ?? "") \(self.storeAddressLine2 ?? "")"
        let storeCityState = "\(self.storeAddressCity ?? "") \(self.storeAddressState ?? "")"
        
        let uploadOrder = UploadOrder(storeName: self.storeName ?? "", storeAddress: storeAddress, storeCityState: storeCityState, zip: self.storeAddressZip ?? "", currentTime: individualOrder.currentTime, photoURL: self.storedProfilePhotoURL)
        
        do {
            try collectionOrders.addDocument(from: uploadOrder) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                    // Hide progress indicator
                    self.hideActivityIndicator()
                    self.navigationController?.popViewController(animated: true)
                    return
                }
                self.hideActivityIndicator()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            print("Error adding document: \(error)")
            self.hideActivityIndicator()
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}


//MARK: adopting required protocols for PHPicker...
extension CreateOrderController:PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        let itemprovider = results.map(\.itemProvider)
        
        for item in itemprovider{
            if item.canLoadObject(ofClass: UIImage.self){
                item.loadObject(ofClass: UIImage.self, completionHandler: { (image, error) in
                    DispatchQueue.main.async{
                        if let uwImage = image as? UIImage{
                                            
                            self.createOrderView.buttonUploadPrescription.setImage(
                                uwImage.withRenderingMode(.alwaysOriginal),
                                for: .normal
                            )
                            
                            // Update button's constraints to adjust the size to 300x400
                            self.createOrderView.buttonUploadPrescription.widthAnchor.constraint(equalToConstant: 300).isActive = true
                            self.createOrderView.buttonUploadPrescription.heightAnchor.constraint(equalToConstant: 400).isActive = true

                            self.pickedImage = uwImage
                        }
                    }
                })
            }
        }
    }
}

//MARK: adopting required protocols for UIImagePicker...
extension CreateOrderController: UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage{
                        
            self.createOrderView.buttonUploadPrescription.setImage(
                image.withRenderingMode(.alwaysOriginal),
                for: .normal
            )
            self.createOrderView.buttonUploadPrescription.widthAnchor.constraint(equalToConstant: 300).isActive = true
            self.createOrderView.buttonUploadPrescription.heightAnchor.constraint(equalToConstant: 400).isActive = true
            self.pickedImage = image
        }
    }
}

extension CreateOrderController:ProgressSpinnerDelegate{
    func showActivityIndicator(){
        addChild(childProgressView)
        view.addSubview(childProgressView.view)
        childProgressView.didMove(toParent: self)
    }
    
    func hideActivityIndicator(){
        childProgressView.willMove(toParent: nil)
        childProgressView.view.removeFromSuperview()
        childProgressView.removeFromParent()
    }
}
