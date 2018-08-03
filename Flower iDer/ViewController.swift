//
//  ViewController.swift
//  Flower iDer
//
//  Created by CURTIS DUNNE on 7/30/18.
//  Copyright © 2018 CURTIS DUNNE. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerDescriptionLabel: UITextView!
    
    var pickedImageSaved: UIImage?
    
    let WIKIPEDIA_URL = "https://en.wikipedia.org/w/api.php"

    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cameraButtonTapped(_ sender: Any) {
        imagePicker.sourceType = .camera
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func imageFolderButtonTapped(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.pickedImageSaved = pickedImage
            
            guard let ciImage = CIImage(image: pickedImage) else {
                fatalError("Could not convert UIImage to CIImage.")
            }
            
            detect(image: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: Flowers_CoreML().model) else {
            fatalError("Loading the CoreML Flower Model Failed.")
        }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Flower Identification Model failed to process Image.")
            }
            
            print("RESULTS: \(results)")
            
            if let classification = request.results?.first as? VNClassificationObservation {
                self.navigationItem.title = classification.identifier.capitalized

                self.getFlowerDataFromWiki(flowerName: classification.identifier)
            } else {
                self.navigationItem.title = "I have no idea what this is....is this really a type of flower?"
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func getFlowerDataFromWiki(flowerName: String) {
        let params: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "pithumbsize": "500",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1"
        ]

        Alamofire.request(WIKIPEDIA_URL, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got Flower data.")
                
                let json = JSON(response.result.value!)
                
                if let pageId = json["query"]["pageids"][0].string {
                    if let flowerDesc = json["query"]["pages"][pageId]["extract"].string {
                        DispatchQueue.main.async {
                            self.flowerDescriptionLabel.text = flowerDesc
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.flowerDescriptionLabel.text = "Flower Description Not Found"
                        }
                    }
                    
                    if let flowerImageURL = json["query"]["pages"][pageId]["thumbnail"]["source"].string {
                        DispatchQueue.main.async {
                            self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.imageView.image = self.pickedImageSaved
                        }
                    }
                }
            }
        }
    }
}

extension ViewController: UINavigationControllerDelegate {



}
