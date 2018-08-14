//
//  TokenObject.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit

// name + symbol to display
// icon if not set it will use local icon saved under symbol.lowercased() name
// for example: ETH, its icon name is eth
public struct KPTokenObject {

  let name: String
  let symbol: String
  let address: String
  let icon: String
  let decimals: Int

  public init(
    name: String,
    symbol: String,
    address: String,
    decimals: Int
    ) {
    self.name = name
    self.symbol = symbol
    self.address = address
    self.icon = symbol.lowercased()
    self.decimals = decimals
  }

  public init(localDict: JSONDictionary) {
    self.name = localDict["name"] as? String ?? ""
    let symbol = localDict["symbol"] as? String ?? ""
    self.symbol = symbol
    self.icon = localDict["icon"] as? String ?? symbol.lowercased()
    self.address = (localDict["address"] as? String ?? "").lowercased()
    self.decimals = localDict["decimal"] as? Int ?? 0
  }

  static public func token(with symbol: String, env: KPEnvironment) -> KPTokenObject? {
    let tokens = KPJSONLoadUtil.loadListSupportedTokensFromJSONFile(env: env)
    return tokens.first(where: { $0.symbol.uppercased() == symbol.uppercased() })
  }

  static public func ethToken(env: KPEnvironment) -> KPTokenObject {
    return self.token(with: "ETH", env: env)!
  }

  var iconURL: String {
    // Token image from Trust public repo
    return "https://raw.githubusercontent.com/TrustWallet/tokens/master/images/\(self.address.lowercased()).png"
  }

  static public func ==(left: KPTokenObject, right: KPTokenObject) -> Bool {
    return left.address == right.address
  }

  static public func !=(left: KPTokenObject, right: KPTokenObject) -> Bool {
    return !(left == right)
  }
}
