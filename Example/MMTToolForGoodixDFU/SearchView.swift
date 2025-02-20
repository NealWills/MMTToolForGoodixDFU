import UIKit
import SnapKit

class SearchView: UIView {

    var searchView: UIView?
    var textField: UITextField?
    var searchButton: UIButton?

    var searchAction: ((String?)->())?
    
    var content: String? {
        set {
            textField?.text = newValue
        }
        get {
            return textField?.text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let searchView = UIView.init(frame: .zero)
        self.addSubview(searchView)
        searchView.snp.makeConstraints({
            $0.leading.equalToSuperview().offset(5)
            $0.trailing.equalToSuperview().offset(-105)
            $0.top.equalToSuperview().offset(5)
            $0.bottom.equalToSuperview().offset(-5)
        })
        searchView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor
        searchView.layer.borderWidth = 1
        searchView.layer.cornerRadius = 25
        searchView.clipsToBounds = true
        
        self.searchView = searchView
        
        let textField = UITextField.init(frame: .zero)
        searchView.addSubview(textField)
        textField.snp.makeConstraints({
            $0.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 5, left: 15, bottom: 5, right: 25))
        })
        textField.delegate = self
        textField.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.placeholder = "Please input content"
        
        self.textField = textField
        
        let searchButton = UIButton.init(frame: .zero)
        self.addSubview(searchButton)
        searchButton.snp.makeConstraints({
            $0.trailing.equalToSuperview().offset(-5)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(80)
            $0.height.equalTo(50)
        })
        searchButton.setTitle("Search", for: UIControlState.normal)
        searchButton.setTitleColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), for: UIControlState.normal)
        searchButton.addTarget(self, action: #selector(searchButtonClickAction(_:)), for: UIControlEvents.touchUpInside)
        
        self.searchButton = searchButton
        
    }
    
    @objc func searchButtonClickAction(_ sender: UIButton) {
        self.textField?.resignFirstResponder()
        self.searchAction?(self.textField?.text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchView: UITextFieldDelegate {
    
    
    
}
