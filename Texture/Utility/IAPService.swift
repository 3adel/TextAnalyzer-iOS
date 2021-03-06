//
//  File.swift
//  Texture
//
//  Created by Halil Gursoy on 28.01.18.
//  Copyright © 2018 Texture. All rights reserved.
//

import Foundation
import SwiftyStoreKit

enum DerSatzIAProduct: IAProduct {
    case premium
    
    var sku: String {
        switch self {
        case .premium: return "com.dersatz.premium"
        }
    }
    
    var trialStartDateUserDefaultsKey: String {
        return UserDefaults.Key.trialStartDate.rawValue + sku
    }
    
    var didPurchaseUserDefaultsKey: String {
        return UserDefaults.Key.didPurchase.rawValue + sku
    }
    
    var didUseProductUserDefaultsKey: String {
        return UserDefaults.Key.didUseProduct.rawValue + sku
    }
    
    static var allProducts: [DerSatzIAProduct]  {
        return [.premium]
    }
    
    static func from(sku: String) -> DerSatzIAProduct? {
        return allProducts.filter { $0.sku == sku }.first
    }
}

protocol IAProduct {
    var sku: String { get }
    var trialStartDateUserDefaultsKey: String { get }
    var didPurchaseUserDefaultsKey: String { get }
    var didUseProductUserDefaultsKey: String { get }
}

extension IAProduct {
    static func ==(lhs: IAProduct, rhs: IAProduct) -> Bool {
        return lhs.sku == rhs.sku
    }
}

extension Array where Element == IAProduct {
    func contains(_ element: Element) -> Bool {
        return contains { $0.sku == element.sku }
    }
}

class IAPService: NSObject, NotificationSender {
    let userDefaults: UserDefaults
    var purchasedProducts: [IAProduct] = []
    var productsInTrial: [IAProduct] = []
    var allAvailableProducts: [IAProduct] = []
    
    var trialDays = 30
    
    enum TransactionResult {
        case success
        case cancelled
        case error(String)
    }
    
    enum Notification: String, NotificationName {
        case didPurchaseProduct
    }
    
    static let shared = IAPService()
    
    init(userDefaults: UserDefaults = .shared) {
        self.userDefaults = userDefaults
        super.init()
        SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
            return self.allAvailableProducts.contains { $0.sku == product.productIdentifier }
        }
    }
    
    func register(products: [IAProduct]) {
        products.forEach {
            guard userDefaults.value(forKey: $0.trialStartDateUserDefaultsKey) as? Date == nil else { return }
            userDefaults.set(Date(), forKey: $0.trialStartDateUserDefaultsKey)
        }
    }
    
    func completeTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { [weak self] purchases in
            self?.purchasedProducts = purchases.filter { $0.transaction.transactionState == .purchased || $0.transaction.transactionState == .restored }.flatMap { DerSatzIAProduct.from(sku: $0.productId) }
            self?.purchasedProducts.forEach { self?.userDefaults.set(true, forKey: $0.didPurchaseUserDefaultsKey) }
        }
    }
    
    func updateStatus(for products: [IAProduct], completion: (() -> Void)? = nil) {
        purchasedProducts = products.filter { userDefaults.bool(forKey: $0.didPurchaseUserDefaultsKey) }
        productsInTrial = products.filter { !purchasedProducts.contains($0) }
        allAvailableProducts = products
        
        completion?()
    }
    
    func daysRemainingInTrial(for product: IAProduct) -> Int {
        guard let date = userDefaults.value(forKey: product.trialStartDateUserDefaultsKey) as? Date else { return trialDays }
        
        let calendar = NSCalendar.current
        let date1 = calendar.startOfDay(for: date)
        let date2 = calendar.startOfDay(for: Date())
        
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        let daysPast = components.day ?? 0
        return trialDays - daysPast
    }
    
    func minutesRemainingInTrial(for product: IAProduct) -> Int {
        guard let date = userDefaults.value(forKey: product.trialStartDateUserDefaultsKey) as? Date else { return trialDays }
        
        let calendar = NSCalendar.current
        
        let components = calendar.dateComponents([.minute], from: date, to: Date())
        let minutesPast = components.minute ?? 0
        return Int(trialDays.minutes - minutesPast.minutes)
    }
    
    func buy(product: IAProduct, completion: ((TransactionResult) -> Void)? = nil) {
        SwiftyStoreKit.purchaseProduct(product.sku, quantity: 1, atomically: true) { result in
            switch result {
            case .success:
                self.didPurchase(product)
                completion?(.success)
            case .error(let error):
                let result: TransactionResult
                switch error.code {
                case .unknown: result = .error("Unknown error. Please contact support")
                case .clientInvalid: result = .error("Not allowed to make the payment")
                case .paymentCancelled: result = .cancelled
                case .paymentInvalid: result = .error("The purchase identifier was invalid")
                case .paymentNotAllowed: result = .error("The device is not allowed to make the payment")
                case .storeProductNotAvailable: result = .error("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: result = .error("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: result = .error("Could not connect to the network")
                case .cloudServiceRevoked: result = .error("You have revoked permission to use this cloud service")
                }
                completion?(result)
            }
        }
    }
    
    func restorePurchase(for product: IAProduct, completion: ((TransactionResult) -> Void)? = nil) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoredPurchases.contains(where: { $0.productId == product.sku }) {
                self.didPurchase(product)
                completion?(.success)
            } else if !results.restoreFailedPurchases.isEmpty {
                completion?(.error("Failed to restore purchases"))
            } else {
                completion?(.cancelled)
            }
        }
    }
    
    func retrievePrice(for product: IAProduct, completion: @escaping (String?) -> Void) {
        SwiftyStoreKit.retrieveProductsInfo([product.sku]) { result in
            guard let productInfo = result.retrievedProducts.first else { completion(nil); return }
            completion(productInfo.localizedPrice)
        }
    }
    
    func productIsPurchased(_ product: IAProduct) -> Bool {
        return purchasedProducts.contains(product)
    }
    
    private func didPurchase(_ product: IAProduct) {
        purchasedProducts.append(product)
        userDefaults.set(true, forKey: product.didPurchaseUserDefaultsKey)
        send(Notification.didPurchaseProduct, userInfo: ["product": product])
    }
}
