//
//  ViewController.swift
//  Stocks
//
//  Created by Timur Saidov on 12.09.2018.
//  Copyright © 2018 Timur Saidov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var companyPriceLabel: UILabel!
    @IBOutlet weak var companyPriceChangeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func updateUI(_ sender: UIBarButtonItem) {
        companies = [:] // Обнуление словаря компаний.
        companyPickerView.reloadAllComponents()
        zeroingUI()
        loadCompaniesArray()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Stocks"
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self // Указываем нашему пикеру, кто тут delegate. Класс View Controller подписывается под то, что он будет исполнять метод протокола UIPickerViewDelegate.
        
        activityIndicator.hidesWhenStopped = true // Отображался только во время анимации.
        
        loadCompaniesArray()
    }
    
    // MARK: - Private properties
    
    private var companies: [String: String] = [:]
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // Вертикальная крутилка с индексом 0.
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }

    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    // Вызван пикером при изменении выбранного элемента.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        zeroingUI() // Может быть в функции requestQuoteUpdate(), но из-за @IBAction func updateUI вынесена в метод picker'а.
        requestQuoteUpdate()
        
//      // Если не использовать метод requestQuoteUpdate().
//        if !activityIndicator.isAnimating {
//            activityIndicator.startAnimating()
//        }
//
//        let selectedSymbol = Array(companies.values)[row]
//        requestQuote(for: selectedSymbol)
    }
    
    // MARK: - Private methods
    
    private func zeroingUI() {
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        companyPriceLabel.text = "-"
        companyPriceChangeLabel.text = "-"
        companyPriceChangeLabel.textColor = UIColor.black
        imageView.image = nil
    }
    
    private func loadCompaniesArray() {
        activityIndicator.startAnimating()
        
        let urlStringCompanies = "https://api.iextrading.com/1.0/stock/market/list/infocus" // Массив словарей.

        guard let url = URL(string: urlStringCompanies) else {
            let ac = UIAlertController(title: "Invalid URL", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            ac.addAction(cancel)
            self.present(ac, animated: true, completion: nil)
            
            print("Error! Invalid URL of companies array!")
            return }

        let dataTaskCompanies = URLSession.shared.dataTask(with: url) { (data, response, error)  in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                let ac = UIAlertController(title: "You are not connected to the Internet.", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                let connect = UIAlertAction(title: "Connect again", style: UIAlertActionStyle.default, handler: { (action) in
                    self.loadCompaniesArray()
                })
                ac.addAction(connect)
                self.present(ac, animated: true, completion: nil)
                
                print("Network error!")
                return }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                print("JSONObject: \(jsonObject)")

                guard let json = jsonObject as? Array<[String: Any]> else {
//                guard let json = jsonObject as? [[String: Any]] else {
//                guard let json = jsonObject as? [Dictionary<String, Any>] else {
//                guard let json = jsonObject as? Array<Dictionary<String, Any>> else {
                        print("Invalid JSON format!")
                        return }
                print("JSON: \(json)")
                
                for i in 0..<json.count {
                    guard let companyName = json[i]["companyName"] as? String,
                        let symbol = json[i]["symbol"] as? String else { return }
                    print("\(companyName), \(symbol)\n")
                    self.companies[companyName] = symbol // Добавление с словарь компаний их назаний, чтобы затем отобразить эти имена в companyPickerView. Как только словарь заполнился, companyPickerView.reloadAllComponents().
                }
                
                DispatchQueue.main.async {
                    self.companyPickerView.reloadAllComponents()
                    self.requestQuoteUpdate() // Если requestQuoteUpdate() не использовать, то добавлять строчки 67-72.
                    print("Companies: \(self.companies)")
                }
    
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }

        dataTaskCompanies.resume()
    }
    
    private func requestQuoteUpdate() {
        if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
        }
        
//        zeroingUI()
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0) // в компоненте (вертикальной крутилке) с индексом 0.
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
    }
    
    private func requestQuote(for symbol: String) {
        let urlString = "https://api.iextrading.com/1.0/stock/\(symbol)/quote" // Словарь.
        let urlStringImage = "https://api.iextrading.com/1.0/stock/\(symbol)/logo"
        
        guard let url = URL(string: urlString), let imageUrlApi = URL(string: urlStringImage) else {
            let ac = UIAlertController(title: "Invalid URL", message: nil, preferredStyle: UIAlertControllerStyle.alert)
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
            ac.addAction(cancel)
            self.present(ac, animated: true, completion: nil)
            
            print("Error! Invalid URL of informations of companies.")
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error)  in
            guard let data = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                let ac = UIAlertController(title: "You are not connected to the Internet.", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                let connect = UIAlertAction(title: "Connect again", style: UIAlertActionStyle.default, handler: { (action) in
                    self.requestQuote(for: symbol)
                })
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
                    (action) in
                    self.activityIndicator.stopAnimating()
                })
                ac.addAction(connect)
                ac.addAction(cancel)
                self.present(ac, animated: true, completion: nil)
                
                print("Network error!")
                return }
            
            print(data)
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                print(jsonObject)
                
                guard
                    let json = jsonObject as? [String: Any],
                    let companyName = json["companyName"] as? String,
                    let companySymbol = json["symbol"] as? String,
                    let companyPrice = json["latestPrice"] as? Double,
                    let companyPriceChange = json["change"] as? Double
                else {
                    print("Invalid JSON format!")
                    return }
                
                print("Company name is \(companyName)")
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.companyNameLabel.text = companyName
                    self.companySymbolLabel.text = companySymbol
                    self.companyPriceLabel.text = "\(companyPrice) $"
                    self.companyPriceChangeLabel.text = "\(companyPriceChange) $"
                    if companyPriceChange < 0 {
                        self.companyPriceChangeLabel.textColor = UIColor.red
                    } else if companyPriceChange > 0 {
                        self.companyPriceChangeLabel.textColor = UIColor.green
                    } else {
                        self.companyPriceChangeLabel.textColor = UIColor.black
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        dataTask.resume()
    
        let dataImageTask = URLSession.shared.dataTask(with: imageUrlApi) { (data, response, error) in
            guard let dataUrlImage = data, (response as? HTTPURLResponse)?.statusCode == 200, error == nil else {
                let ac = UIAlertController(title: "You are not connected to the Internet.", message: nil, preferredStyle: UIAlertControllerStyle.alert)
                let connect = UIAlertAction(title: "Connect again", style: UIAlertActionStyle.default, handler: { (action) in
                    self.requestQuote(for: symbol)
                })
                let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
                    (action) in
                    self.activityIndicator.stopAnimating()
                })
                ac.addAction(connect)
                ac.addAction(cancel)
                self.present(ac, animated: true, completion: nil)
                
                print("Network error!")
                return }

            print(dataUrlImage)
            
            do {
                let jsonImage = try JSONSerialization.jsonObject(with: dataUrlImage)
                print(jsonImage)
                
                guard let json = jsonImage as? [String: String] else { return }
                guard let imageUrl = json["url"] else { return }
                
                if let imageUrl = URL(string: imageUrl) {
                    URLSession.shared.dataTask(with: imageUrl) { (data, _, _) in
                        if let dataImage = data, let image = UIImage(data: dataImage) {
                            DispatchQueue.main.async {
                                self.imageView.image = image
                            }
                        }
                    }.resume()
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        
        dataImageTask.resume()
    }
}
