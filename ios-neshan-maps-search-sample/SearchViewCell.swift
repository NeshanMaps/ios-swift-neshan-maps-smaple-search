//
//  SearchViewCell.swift
//  ios-neshan-maps-search-sample
//
//  Created by M.Madadi on 12/24/18.
//  Copyright © 2018 Rajman. All rights reserved.
//

import UIKit

class SearchViewCell: UITableViewCell {
    // We have 2 label in each tableViewCell -> Title and Address
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // setSearchResult function for setting Title Result and Address Result to cell labels
    func setSearchResult(title: String, address: String) {
        titleLabel.text = title
        addressLabel.text = address
    }

}
