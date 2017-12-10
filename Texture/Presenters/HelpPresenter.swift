//
//  HelpPresenter.swift
//  Texture
//
//  Created by Halil Gursoy on 07.12.17.
//  Copyright © 2017 Texture. All rights reserved.
//

import Foundation
import RVMP

class HelpPresenter: Presenter, HelpPresenterType {
    fileprivate var helpView: HelpView? {
        return view as? HelpView
    }
    
    override func getInitialData() {
        guard let url = URL(string: "http://3e105a6deba8438da3b6cd03456acb51.yatu.ws/help.html") else { return }
        let helpViewModel = HelpViewModel(url: url)
        helpView?.render(with: helpViewModel)
    }
}
