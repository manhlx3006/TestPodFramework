//
//  KPPayViewController.swift
//  KyberPayiOS
//
//  Created by Manh Le on 6/8/18.
//  Copyright © 2018 manhlx. All rights reserved.
//

import UIKit
import BigInt

public enum KPPayViewEvent {
  case close
  case selectToken(token: KPTokenObject)
  case getBalance(token: KPTokenObject)
  case estGastLimit(payment: KPPayment)
  case estSwapRate(from: KPTokenObject, to: KPTokenObject, amount: BigInt)
  case process(payment: KPPayment)
}

public protocol KPPayViewControllerDelegate: class {
  func payViewController(_ controller: KPPayViewController, run event: KPPayViewEvent)
}

public class KPPayViewController: UIViewController {

  weak var delegate: KPPayViewControllerDelegate?
  fileprivate var viewModel: KPPayViewModel

  @IBOutlet weak var scrollContainerView: UIScrollView!

  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var receiverAddressLabel: UILabel!
  @IBOutlet weak var srcAddressLabel: UILabel!

  @IBOutlet weak var srcTokenButton: UIButton!
  @IBOutlet weak var srcAmountTextField: UITextField!

  @IBOutlet weak var receiverTokenButton: UIButton!
  @IBOutlet weak var receiverAmountTextField: UITextField!

  @IBOutlet weak var tokenBalanceTextLabel: UILabel!
  @IBOutlet weak var tokenBalanceValueLabel: UILabel!

  @IBOutlet weak var estimatedRateValueLabel: UILabel!

  @IBOutlet weak var advanceSettingsOptionButton: UIButton!

  @IBOutlet weak var advancedSettingsView: UIView!
  @IBOutlet weak var gasPriceSegmentedControl: UISegmentedControl!
  @IBOutlet weak var gasPriceTextField: UITextField!

  @IBOutlet weak var minRateSlider: CustomSlider!
  @IBOutlet weak var minRatePercentLabel: UILabel!
  @IBOutlet weak var leadingConstraintForMinRatePercentLabel: NSLayoutConstraint!
  @IBOutlet weak var minRateValueLabel: UILabel!
  @IBOutlet weak var heightConstaintForAdvancedSettingsView: NSLayoutConstraint!

  @IBOutlet weak var payButton: UIButton!

  fileprivate var loadTimer: Timer?

  public init(viewModel: KPPayViewModel) {
    self.viewModel = viewModel
    super.init(nibName: "KPPayViewController", bundle: nil)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.loadTimer?.invalidate()
    self.reloadDataFromNode()
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.reloadDataFromNode()
    })
  }

  override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.tokenContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.5),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
  }

  fileprivate func setupUI() {
    self.setupTokenContainerView()
    self.setupAdvancedSettingsView()
  }

  fileprivate func setupTokenContainerView() {
    self.receiverAddressLabel.text = self.viewModel.displayReceiverAddress
    self.srcAddressLabel.text = self.viewModel.displaySrcAddressString

    self.srcAmountTextField.text = ""
    self.viewModel.updateFromAmount("")
    self.srcAmountTextField.adjustsFontSizeToFitWidth = true

    self.srcAmountTextField.delegate = self

    if self.viewModel.receiverTokenAmount != nil {
      self.receiverAmountTextField.text = self.viewModel.displayReceiverAmount
      self.srcAmountTextField.text = self.viewModel.estimatedFromAmountDisplay
      self.viewModel.updateFromAmount(self.srcAmountTextField.text ?? "")
      self.srcAmountTextField.isEnabled = false
    }
    self.receiverAmountTextField.adjustsFontSizeToFitWidth = true
    // Disable typing dest amount as new behaviour changed for web
    self.receiverAmountTextField.isEnabled = false

    self.srcTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: true),
      for: .normal
    )
    self.srcTokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.srcTokenButton.titleLabel?.numberOfLines = 2
    self.srcTokenButton.titleLabel?.lineBreakMode = .byWordWrapping

    self.receiverTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: false),
      for: .normal
    )
    self.receiverTokenButton.setTokenImage(
      token: self.viewModel.receiverToken,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.receiverTokenButton.semanticContentAttribute = .forceRightToLeft
    self.receiverTokenButton.titleLabel?.numberOfLines = 2
    self.receiverTokenButton.titleLabel?.lineBreakMode = .byWordWrapping

    self.updateBalanceAndRate()
  }

  fileprivate func setupAdvancedSettingsView() {
    self.gasPriceSegmentedControl.selectedSegmentIndex = 0
    self.viewModel.updateSelectedGasPriceType(.fast)
    self.gasPriceSegmentedControl.addTarget(self, action: #selector(self.gasPriceSegmentedControlDidTouch(_:)), for: .touchDown)
    
    self.minRateSlider.isEnabled = self.viewModel.from != self.viewModel.receiverToken
    self.minRateSlider.addTarget(self, action: #selector(self.minRatePercentDidChange(_:)), for: .valueChanged)
    self.minRateSlider.value = self.viewModel.currentMinRatePercentValue
    self.minRateValueLabel.text = self.viewModel.minRateText
    self.minRatePercentLabel.text = self.viewModel.currentMinRatePercentText
    self.leadingConstraintForMinRatePercentLabel.constant = (self.minRateSlider.frame.width - 32.0) * CGFloat(self.viewModel.currentMinRatePercentValue / 100.0)
    
    self.advancedSettingsView.isHidden = true
    self.heightConstaintForAdvancedSettingsView.constant = 0

    self.advanceSettingsOptionButton.setTitle(
      "Show Settings",
      for: .normal
    )

    self.payButton.rounded(radius: self.payButton.frame.height / 2.0)
  }

  fileprivate func updateBalanceAndRate() {
    self.tokenBalanceTextLabel.text = self.viewModel.balanceTextString
    self.tokenBalanceValueLabel.text = self.viewModel.balanceValueString
    self.estimatedRateValueLabel.text = self.viewModel.exchangeRateText
    
    self.minRateSlider.isEnabled = self.viewModel.from != self.viewModel.receiverToken
    self.minRateSlider.value = self.viewModel.currentMinRatePercentValue
    self.minRateValueLabel.text = self.viewModel.minRateText
    self.minRatePercentLabel.text = self.viewModel.currentMinRatePercentText
  
    self.leadingConstraintForMinRatePercentLabel.constant = (self.minRateSlider.frame.width - 32.0) * CGFloat(self.viewModel.currentMinRatePercentValue / 100.0)
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
  }

  @IBAction func srcTokenButtonPressed(_ sender: Any) {
  }

  @IBAction func advancedSettingsOptionPressed(_ sender: Any) {
    let isHidden = !self.advancedSettingsView.isHidden
    UIView.animate(
      withDuration: 0.25,
      animations: {
        if isHidden { self.advancedSettingsView.isHidden = isHidden }
        self.heightConstaintForAdvancedSettingsView.constant = isHidden ? 0.0 : 220.0
        self.advanceSettingsOptionButton.setTitle(
          isHidden ? "Show Settings" : "Hide Settings",
          for: .normal
        )
        self.view.layoutIfNeeded()
    }, completion: { _ in
      self.advancedSettingsView.isHidden = isHidden
      if !self.advancedSettingsView.isHidden {
        let bottomOffset = CGPoint(
          x: 0,
          y: self.scrollContainerView.contentSize.height - self.scrollContainerView.bounds.size.height
        )
        self.scrollContainerView.setContentOffset(bottomOffset, animated: true)
      }
    })
  }

  @objc func gasPriceSegmentedControlDidTouch(_ sender: Any) {
    let selectedId = self.gasPriceSegmentedControl.selectedSegmentIndex
    self.viewModel.updateSelectedGasPriceType(KPGasPriceType(rawValue: selectedId) ?? KPGasPriceType.fast)
  }

  @objc func minRatePercentDidChange(_ sender: CustomSlider) {
    let value = Int(floor(sender.value))
    self.viewModel.updateExchangeMinRatePercent(Double(value))
    self.minRateSlider.value = self.viewModel.currentMinRatePercentValue
    self.minRateValueLabel.text = self.viewModel.minRateText
    self.minRatePercentLabel.text = self.viewModel.currentMinRatePercentText
    self.leadingConstraintForMinRatePercentLabel.constant = (self.minRateSlider.frame.width - 32.0) * CGFloat(self.viewModel.currentMinRatePercentValue / 100.0)
    self.view.layoutIfNeeded()
  }

  @IBAction func proceedButtonPressed(_ sender: Any) {
  }

  fileprivate func reloadDataFromNode() {
    let balanceEvent = KPPayViewEvent.getBalance(
      token: self.viewModel.from
    )
    self.delegate?.payViewController(self, run: balanceEvent)
    let estRateEvent = KPPayViewEvent.estSwapRate(
      from: self.viewModel.from,
      to: self.viewModel.receiverToken,
      amount: self.viewModel.amountFromBigInt
    )
    self.delegate?.payViewController(self, run: estRateEvent)
    let estGasLimitEvent = KPPayViewEvent.estGastLimit(payment: self.viewModel.payment)
    self.delegate?.payViewController(self, run: estGasLimitEvent)
  }
}

extension KPPayViewController: UITextFieldDelegate {
  public func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateFromAmount("")
    self.updateViewAmountDidChange()
    return false
  }

  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if textField == self.srcAmountTextField, text.fullBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    if text.isEmpty || Double(text) != nil {
      textField.text = text
      self.viewModel.updateFromAmount(text)
      self.updateViewAmountDidChange()
    }
    return false
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.receiverTokenAmount == nil {
      self.receiverAmountTextField.text = self.viewModel.estimatedReceivedAmountDisplay
    } else {
      self.srcAmountTextField.text = self.viewModel.estimatedFromAmountDisplay
      self.viewModel.updateFromAmount(self.srcAmountTextField.text ?? "")
    }
  }
}

extension KPPayViewController {
  func coordinatorUpdateBalance(for token: KPTokenObject, balance: BigInt) {
    if token == self.viewModel.from {
      self.viewModel.updateBalance([token.address: balance])
      self.tokenBalanceValueLabel.text = self.viewModel.balanceValueString
    }
  }

  func coordinatorUpdateExpectedRate(from: KPTokenObject, to: KPTokenObject, amount: BigInt, expectedRate: BigInt, slippageRate: BigInt) {
    self.viewModel.updateExchangeRate(
      for: from,
      to: to,
      amount: amount,
      rate: expectedRate,
      slippageRate: slippageRate
    )
    self.updateBalanceAndRate()
    self.updateViewAmountDidChange()
  }

  func coordinatorUpdatePayToken(_ token: KPTokenObject) {
    self.viewModel.updateSelectedToken(token)
    self.minRateSlider.isEnabled = self.viewModel.from != self.viewModel.receiverToken
  
    self.srcTokenButton.setAttributedTitle(
      self.viewModel.tokenButtonAttributedText(isSource: true),
      for: .normal
    )
    self.srcTokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )

    self.srcAmountTextField.text = ""
    self.viewModel.updateFromAmount("")
    self.reloadDataFromNode()
    self.updateBalanceAndRate()
    self.updateViewAmountDidChange()
  }

  func coordinatorUpdateEstGasLimit(_ limit: BigInt, payment: KPPayment) {
    self.viewModel.updateEstimateGasLimit(
      for: payment.from,
      to: payment.to,
      amount: payment.amountFrom,
      gasLimit: limit
    )
  }
}

class CustomSlider: UISlider {
  override func trackRect(forBounds bounds: CGRect) -> CGRect {
    let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: 8.0))
    super.trackRect(forBounds: customBounds)
    return customBounds
  }
}
