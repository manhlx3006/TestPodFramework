//
//  KPPayment.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt

public struct KPPayment {
  // Pay from token to token, from and to can be the same
  let from: KPTokenObject
  let to: KPTokenObject
  // source wallet to pay
  let srcWallet: String
  // wallet to pay to
  let destWallet: String
  // Amount from
  let amountFrom: BigInt
  // Only set this value if you want to pay a fixed amount
  let amountTo: BigInt?
  // Only if from != to
  let minRate: BigInt?

  let gasPrice: BigInt?
  let gasLimit: BigInt?
}
