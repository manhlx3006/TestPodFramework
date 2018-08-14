// Copyright SIX DAY LLC. All rights reserved.

import UIKit

public enum KPEnvironment: Int {

  case mainnetTest = 0
  case production = 1
  case staging = 2
  case ropsten = 3
  case kovan = 4

  var displayName: String {
    switch self {
    case .mainnetTest: return "Mainnet"
    case .production: return "Production"
    case .staging: return "Staging"
    case .ropsten: return "Ropsten"
    case .kovan: return "Kovan"
    }
  }

  static let allEnvs: [KPEnvironment] = [
    KPEnvironment.mainnetTest,
    KPEnvironment.production,
    KPEnvironment.staging,
    KPEnvironment.ropsten,
    KPEnvironment.kovan,
  ]

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.customRPC?.etherScanEndpoint ?? ""
  }

  var customRPC: KPCustomRPC? {
    guard let json = KPJSONLoadUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KPCustomRPC(dictionary: json)
  }

  var configFileName: String {
    switch self {
    case .mainnetTest: return "config_env_mainnet_test"
    case .production: return "config_env_production"
    case .staging: return "config_env_staging"
    case .ropsten: return "config_env_ropsten"
    case .kovan: return "config_env_kovan"
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .mainnetTest: return "http://api.etherscan.io/"
    case .production: return "http://api.etherscan.io/"
    case .staging: return "http://api-kovan.etherscan.io/"
    case .ropsten: return "http://api-ropsten.etherscan.io/"
    case .kovan: return "http://api-kovan.etherscan.io/"
    }
  }
}
