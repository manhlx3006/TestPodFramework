// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIButton {
  func setImage(
    with url: URL,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.setImage(image.resizeImage(to: size), for: .normal)
        }
      }
    }.resume()
  }

  func setImage(
    with string: String,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    guard let url = URL(string: string) else { return }
    self.setImage(
      with: url,
      placeHolder: placeHolder,
      size: size,
      state: state
    )
  }

  func setTokenImage(
    token: KPTokenObject,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    if let image = UIImage(named: token.icon.lowercased()) {
      self.setImage(image.resizeImage(to: size), for: .normal)
    } else {
      let placeHolderImg = UIImage(named: "default_token")
      self.setImage(
        with: token.iconURL,
        placeHolder: placeHolderImg,
        size: size,
        state: state
      )
    }
  }
}
