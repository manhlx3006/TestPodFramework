//
//  KPGasConfiguration.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//
import BigInt

public struct KPGasConfiguration {
  static let exchangeTokensGasLimitDefault = BigInt(660_000)
  static let transferTokenGasLimitDefault = BigInt(60_000)
  static let transferETHGasLimitDefault = BigInt(21_000)

  static let gasPriceFast = BigInt(15_000_000_000)
  static let gasPriceMedium = BigInt(10_000_000_000)
  static let gasPriceSlow = BigInt(5_000_000_000)
  static let gasPriceMax = BigInt(50_000_000_000)
}
