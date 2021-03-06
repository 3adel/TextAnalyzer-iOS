//
//  SavedInterface.swift
//  Texture
//
//  Created by Halil Gursoy on 10.12.17.
//  Copyright © 2017 Texture. All rights reserved.
//

import Foundation
import RVMP

protocol SavedViewProtocol: View {
    func render(with viewModel: [SavedArticleViewModel])
    func update(viewModels: [SavedArticleViewModel]) 
}

protocol SavedPresenterProtocol: BasePresenter {
    func didTapOnArticle(at index: Int)
    func didTapDeleteForArticle(at index: Int, completionHandler: @escaping (Bool) -> Void)
}
