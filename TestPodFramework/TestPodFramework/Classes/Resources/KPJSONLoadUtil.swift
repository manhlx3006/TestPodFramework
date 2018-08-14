// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public typealias JSONDictionary = [String: Any]

public class KPJSONLoadUtil {

  static let shared = KPJSONLoadUtil()

  static public func loadListSupportedTokensFromJSONFile(env: KPEnvironment) -> [KPTokenObject] {
    guard let json = KPJSONLoadUtil.jsonDataFromFile(with: env.configFileName) else { return [] }
    guard let tokensJSON = json["tokens"] as? JSONDictionary else { return [] }
    let tokens = tokensJSON.values.map({ return KPTokenObject(localDict: $0 as? JSONDictionary ?? [:]) })
    return tokens
  }

  static public func jsonDataFromFile(with name: String) -> JSONDictionary? {
    guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
      print("---> Error: File not found with name \(name)")
      return nil
    }
    let urlPath = URL(fileURLWithPath: path)
    var data: Data? = nil
    do {
      data = try Data(contentsOf: urlPath)
    } catch let error {
      print("---> Error: Get data from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    guard let jsonData = data else {
      print("---> Error: Can not cast data from file \(name) to json")
      return nil
    }
    do {
      let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
      // TODO: Data might be an array
      if let objc = json as? JSONDictionary { return objc }
    } catch let error {
      print("---> Error: Cast json from file path \(urlPath.absoluteString) failed with error \(error.localizedDescription)")
      return nil
    }
    return nil
  }
}
