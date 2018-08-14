// Copyright SIX DAY LLC. All rights reserved.

import UIKit

public struct KPCustomRPC {

  let chainID: Int
  let chainName: String
  let endpoint: String

  let networkAddress: String
  let authorizedAddress: String
  let tokenIEOAddress: String
  let reserveAddress: String
  let etherScanEndpoint: String
  let tradeTopic: String

  public init(dictionary: JSONDictionary) {
    self.chainID = dictionary["networkId"] as? Int ?? 0
    self.chainName = dictionary["chainName"] as? String ?? ""
    self.endpoint = {
      var endpoint: String
      if let connections: JSONDictionary = dictionary["connections"] as? JSONDictionary,
        let https: [JSONDictionary] = connections["http"] as? [JSONDictionary] {
        let endpointJSON: JSONDictionary = https.count > 1 ? https[1] : https[0]
        endpoint = endpointJSON["endPoint"] as? String ?? ""
      } else {
        endpoint = dictionary["endpoint"] as? String ?? ""
      }
      return endpoint
    }()
    self.networkAddress = dictionary["network"] as? String ?? ""
    self.authorizedAddress = dictionary["authorize_contract"] as? String ?? ""
    self.tokenIEOAddress = dictionary["token_ieo"] as? String ?? ""
    self.reserveAddress = dictionary["reserve"] as? String ?? ""
    self.etherScanEndpoint = dictionary["ethScanUrl"] as? String ?? ""
    self.tradeTopic = dictionary["trade_topic"] as? String ?? ""
  }
}
