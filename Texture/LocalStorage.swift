//
//  LocalStorage.swift
//  Texture
//
//  Created by Halil Gursoy on 04.12.17.
//  Copyright © 2017 Texture. All rights reserved.
//

import Foundation

protocol LocalStorageProtocol {
    func getSavedArticles() -> [Article]
    func save(_ article: Article) -> Bool
    func delete(_ article: Article) -> Bool
}

class LocalStorage: LocalStorageProtocol {
    static var shared: LocalStorage = LocalStorage()
    
    private let savedArticlesKey = "savedArticles"
    private let appGroupID = "group.de.texture"
    
    private lazy var savedArticlesPath: String = {
        let documentURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        return documentURL!.appendingPathComponent(savedArticlesKey).path
    }()
    
    private lazy var currentSavedArticles: [Article] = []
    
    init() {
        currentSavedArticles = loadSavedArticles()
    }
    
    func getSavedArticles() -> [Article] {
        currentSavedArticles = loadSavedArticles()
        return currentSavedArticles
    }
    
    private func loadSavedArticles() -> [Article] {
        guard let data = NSKeyedUnarchiver.unarchiveObject(withFile: savedArticlesPath) as? Data,
            let articles = try? JSONDecoder().decode([Article].self, from: data)
            else { return [] }
        
        return articles
    }
    
    @discardableResult
    func save(_ article: Article) -> Bool {
        guard !currentSavedArticles.contains(article) else { return true }
        
        currentSavedArticles.append(article)
        return save(articles: currentSavedArticles)
    }
    
    @discardableResult
    func delete(_ article: Article) -> Bool {
        guard let index = currentSavedArticles.index(of: article) else { return false }
        currentSavedArticles.remove(at: index)
        return save(articles: currentSavedArticles)
    }
    
    @discardableResult
    private func save(articles: [Article]) -> Bool {
        guard let jsonData = try? JSONEncoder().encode(articles) else { return false }
        
        NSKeyedArchiver.archiveRootObject(jsonData, toFile: savedArticlesPath)
        return true
    }
}
