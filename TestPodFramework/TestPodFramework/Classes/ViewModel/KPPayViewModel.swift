//
//  KPPayViewModel.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt

public enum KPGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case custom = 3
}

public struct KPPayViewModel {
  let defaultTokenIconImg = UIImage(named: "default_token")

  let receiverAddress: String
  let receiverToken: KPTokenObject
  let receiverTokenAmount: String?
  let callback: String?
  let network: KPEnvironment
  let srcAddress: String

  fileprivate(set) var tokens: [KPTokenObject] = []

  fileprivate(set) var from: KPTokenObject
  fileprivate(set) var amountFrom: String = ""

  // Balance
  fileprivate(set) var balances: [String: BigInt] = [:]
  fileprivate(set) var balance: BigInt?
  
  // Rate
  fileprivate(set) var estimatedRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double?

  // Gas Price
  fileprivate(set) var gasPriceType: KPGasPriceType = .fast
  fileprivate(set) var gasPrice: BigInt = KPGasConfiguration.gasPriceFast

  fileprivate(set) var gasLimit: BigInt = KPGasConfiguration.exchangeTokensGasLimitDefault

  public init(
    receiverAddress: String,
    receiverToken: KPTokenObject,
    receiverTokenAmount: String?,
    callback: String?,
    network: KPEnvironment,
    srcAddress: String
    ) {
    self.receiverAddress = receiverAddress
    self.receiverToken = receiverToken
    self.receiverTokenAmount = receiverTokenAmount
    self.callback = callback
    self.network = network
    self.srcAddress = srcAddress

    self.tokens = KPJSONLoadUtil.loadListSupportedTokensFromJSONFile(env: self.network)
    self.from = KPTokenObject.ethToken(env: network)

    self.gasLimit = {
      if self.from == self.receiverToken {
        // normal transfer
        if self.from.symbol == "ETH" { return KPGasConfiguration.transferETHGasLimitDefault }
        return KPGasConfiguration.transferTokenGasLimitDefault
      }
      return KPGasConfiguration.exchangeTokensGasLimitDefault
    }()
  }

  var payment: KPPayment {
    return KPPayment(
      from: self.from,
      to: self.receiverToken,
      srcWallet: self.srcAddress,
      destWallet: self.receiverAddress,
      amountFrom: self.amountFromBigInt,
      amountTo: self.receiverAmountBigInt,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: self.gasLimit
    )
  }
}

// MARK: Source data
extension KPPayViewModel {
  var displaySrcAddressString: String {
    return "From:      \(self.srcAddress.prefix(8))...\(self.srcAddress.suffix(6))"
  }

  var allFromTokenBalanceString: String {
    return self.balance?.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: self.from.decimals
      ) ?? ""
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.fullBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var estimatedFromAmountBigInt: BigInt? {
    guard let receivedAmount = self.receiverAmountBigInt else { return nil }
    if self.from == self.receiverToken { return receivedAmount }
    guard let rate = self.estimatedRate, !rate.isZero else { return nil }
    return receivedAmount * BigInt(10).power(self.from.decimals) / rate
  }

  var estimatedFromAmountDisplay: String? {
    guard let estAmount = self.estimatedFromAmountBigInt else { return nil }
    return "\(estAmount.string(decimals: self.from.decimals, minFractionDigits: 0, maxFractionDigits: 9))"
  }
}

// MARK: Receiver Data
extension KPPayViewModel {
  var displayReceiverAddress: String {
    return "To:      \(self.receiverAddress.prefix(8))...\(self.receiverAddress.suffix(6))"
  }

  var receiverAmountBigInt: BigInt? {
    guard let receiverAmount = self.receiverTokenAmount else { return nil }
    return receiverAmount.fullBigInt(decimals: self.receiverToken.decimals)
  }

  var displayReceiverAmount: String {
    if let amount = self.receiverTokenAmount {
      return "\(amount)"
    }
    return ""
  }

  // In case user has not given received amount
  var estimatedReceivedAmountBigInt: BigInt? {
    guard let rate = self.estimatedRate else { return nil }
    return rate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
  }

  var estimatedReceivedAmountDisplay: String? {
    guard let estReceived = self.estimatedReceivedAmountBigInt else { return nil }
    return estReceived.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 6)
  }
}

// MARK: Rate
extension KPPayViewModel {
  var exchangeRateText: String {
    let rateString: String = self.estimatedRate?.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 9) ?? "---"
    return "\(rateString)"
  }

  var minRate: BigInt? {
    if let double = self.minRatePercent, let estRate = self.estimatedRate {
      return estRate * BigInt(double) / BigInt(100)
    }
    return self.slippageRate
  }

  var minRateText: String? {
    return self.minRate?.string(decimals: self.receiverToken.decimals, minFractionDigits: 0, maxFractionDigits: 9)
  }

  var currentMinRatePercentValue: Float {
    if let double = self.minRatePercent { return Float(floor(double)) }
    guard let estRate = self.estimatedRate, let slippageRate = self.slippageRate, !estRate.isZero else { return 100.0 }
    return Float(floor(Double(slippageRate * BigInt(100) / estRate)))
  }

  var currentMinRatePercentText: String {
    let value = self.currentMinRatePercentValue
    return "\(Int(floor(value)))%"
  }
}

// MARK: Advanced Settings {
extension KPPayViewModel {
  // Balance
  var balanceValueString: String {
    let bal: BigInt = self.balance ?? BigInt(0)
    return "\(bal.shortString(decimals: self.from.decimals))"
  }

  var balanceTextString: String {
    return "\(self.from.symbol) Balance"
  }

  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }
}


// MARK: Validate data
extension KPPayViewModel {
  // Validate amount
  var isAmountTooSmall: Bool {
    if self.receiverTokenAmount != nil { return false }
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.symbol == "ETH" {
      return self.amountFromBigInt <= BigInt(0.001 * Double(KPEthereumUnit.ether.rawValue))
    }
    if self.receiverToken.symbol == "ETH" {
      return self.estimatedReceivedAmountBigInt ?? BigInt(0) <= BigInt(0.001 * Double(KPEthereumUnit.ether.rawValue))
    }
    return false
  }

  var isAmountTooBig: Bool {
    let balance: BigInt = self.balance ?? BigInt(0)
    if let amount = self.estimatedFromAmountBigInt {
      return amount > balance
    }
    return self.amountFromBigInt > balance
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // Validate Rate
  var isRateValid: Bool {
    if self.from == self.receiverToken { return true }
    if self.estimatedRate == nil || self.estimatedRate!.isZero { return false }
    if self.minRate == nil || self.minRate!.isZero { return false }
    return true
  }

  var isMinRateValidForTransaction: Bool {
    // If did not specify amount, always valid
    guard let receiveAmount = self.receiverAmountBigInt else { return true }
    guard let minRate = self.minRate, !minRate.isZero else { return false }
    let estAmount = receiveAmount * BigInt(10).power(self.from.decimals) / minRate
    return estAmount <= (self.balance ?? BigInt(0))
  }

  // MARK: Helpers
  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.medium),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular),
      NSAttributedStringKey.foregroundColor: UIColor(hex: "5a5e67"),
    ]
    let symbol = isSource ? self.from.symbol : self.receiverToken.symbol
    let name = isSource ? self.from.name : self.receiverToken.name
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }
}

// MARK: Update data
extension KPPayViewModel {
  mutating func updateSelectedToken(_ token: KPTokenObject) {
    if self.from == token { return }
    self.from = token
    self.amountFrom = ""
    self.estimatedRate = nil
    self.slippageRate = nil
    self.gasLimit = {
      if self.receiverToken != self.from { return KPGasConfiguration.exchangeTokensGasLimitDefault }
      if self.from.symbol == "ETH" { return KPGasConfiguration.transferETHGasLimitDefault }
      return KPGasConfiguration.transferTokenGasLimitDefault
    }()
    self.balance = self.balances[self.from.address]
  }

  mutating func updateFromAmount(_ amount: String) {
    self.amountFrom = amount
  }

  mutating func updateBalance(_ balances: [String: BigInt]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.address] {
      self.balance = bal
    }
  }

  mutating func updateSelectedGasPriceType(_ type: KPGasPriceType) {
    self.gasPriceType = type
    switch type {
    case .fast:
      self.gasPrice = KPGasConfiguration.gasPriceFast
    case .medium:
      self.gasPrice = KPGasConfiguration.gasPriceMedium
    case .slow:
      self.gasPrice = KPGasConfiguration.gasPriceSlow
    default: break
    }
  }

  mutating func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.gasPriceType = .custom
  }

  mutating func updateExchangeRate(for from: KPTokenObject, to: KPTokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    if from == self.from, to == self.receiverToken, amount == self.amountFromBigInt {
      self.estimatedRate = rate
      if rate.isZero {
        self.slippageRate = slippageRate
      } else {
        let percent = Double(slippageRate * BigInt(100) / rate)
        self.slippageRate = rate * BigInt(Int(floor(percent))) / BigInt(100)
      }
    }
  }

  mutating func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  mutating func updateEstimateGasLimit(for from: KPTokenObject, to: KPTokenObject, amount: BigInt, gasLimit: BigInt) {
    if from == self.from, to == self.receiverToken, amount == self.amountFromBigInt {
      self.gasLimit = gasLimit
    }
  }
}
