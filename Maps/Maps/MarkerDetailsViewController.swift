//
//  MarkerDetailsViewController.swift
//  Maps
//
//  Created by Tuyen Tran on 12/17/19.
//  Copyright © 2019 Tuyen Tran. All rights reserved.
//

import UIKit

class MarkerDetailsViewController: UIViewController
{
    var addressString = String()

    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        backBtn.layer.cornerRadius = 5.0
        addressLabel.text = addressString
        
    }
    @IBAction func closePopUp(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
}
