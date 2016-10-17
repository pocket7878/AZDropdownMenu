//
//  AppDelegate.swift
//  AZDropdownMenu
//
//  Created by Chris Wu on 01/05/2016.
//  Copyright (c) 2016 Chris Wu. All rights reserved.
//

import UIKit

@objc public protocol AZDropdownMenuDelegate {
    func onOpenAZDropdownMenu(_ menu: AZDropdownMenu)
    @objc optional func onOpenAZDropdownMenuFinished(_ menu: AZDropdownMenu)
    
    func onCloseAZDropdownMenu(_ menu: AZDropdownMenu)
    @objc optional func onCloseAZDropdownMenuFinished(_ menu: AZDropdownMenu)
}

open class AZDropdownMenu: UIView {
    
    fileprivate let DROPDOWN_MENU_CELL_KEY : String = "MenuItemCell"

    /// The dark overlay behind the menu
    fileprivate let overlay:UIView = UIView()
    fileprivate var menuView: UITableView!
    
    /// Array of titles for the menu
    fileprivate var titles = [String]()
    
    /// Property to figure out if initial layout has been configured
    fileprivate var isSetUpFinished : Bool

    /// The handler used when menu item is tapped
    open var cellTapHandler : ((_ indexPath:IndexPath) -> Void)?
    
    // MARK: - Configuration options
    /// Delegate of menu open & close
    open var delegate: AZDropdownMenuDelegate?
    
    /// Top offset of menu
    open var menuTopOffset : CGFloat = 0.0 {
        didSet {
            self.menuConfig?.menuTopOffset = menuTopOffset
            self.menuView.frame = CGRect(x: 0, y: menuTopOffset, width: frame.size.width, height: menuHeight)
        }
    }

    /// Row height of the menu item
    open var itemHeight : Int = 44 {
        didSet {
            let menuFrame = CGRect(x: 0, y: menuTopOffset, width: frame.size.width, height: menuHeight)
            self.menuView.frame = menuFrame
        }
    }
    
    /// The color of the menu item
    open var itemColor : UIColor = UIColor.white {
        didSet {
            self.menuConfig?.itemColor = itemColor
        }
    }
 
    /// The background color of the menu item while being tapped
    open var itemSelectionColor : UIColor = UIColor.lightGray {
        didSet {
            self.menuConfig?.itemSelectionColor = itemSelectionColor
        }
    }
    
    /// The font of the item
    open var itemFontName : String = "Helvetica" {
        didSet {
            self.menuConfig?.itemFont = itemFontName
        }
    }

    /// The text color of the menu item
    open var itemFontColor : UIColor = UIColor(red: 140/255, green: 134/255, blue: 125/255, alpha: 1.0) {
        didSet {
            self.menuConfig?.itemFontColor = itemFontColor
        }
    }
    
    /// Font size of the menu item
    open var itemFontSize : CGFloat = 14.0 {
        didSet {
            self.menuConfig?.itemFontSize = itemFontSize
        }
    }
    
    /// The alpha for the background overlay
    open var overlayAlpha : CGFloat = 0.5 {
        didSet {
            self.menuConfig?.overlayAlpha = self.overlayAlpha
        }
    }
    
    /// Color for the background overlay
    open var overlayColor : UIColor = UIColor.black {
        didSet {
            self.overlay.backgroundColor = self.overlayColor
            self.menuConfig?.overlayColor = self.overlayColor
        }
    }
    
    open var menuSeparatorStyle:AZDropdownMenuSeperatorStyle = .singleline {
        didSet {
            switch(menuSeparatorStyle){
                case .none:
                    self.menuView.separatorStyle = .none
                    self.menuConfig?.menuSeparatorStyle = .none
                case .singleline:
                    self.menuView.separatorStyle = .singleLine
                    self.menuConfig?.menuSeparatorStyle = .singleline
            }
        }
    }
    
    open var menuSeparatorColor:UIColor = UIColor.lightGray {
        didSet {
            self.menuConfig?.menuSeparatorColor = self.menuSeparatorColor
            self.menuView.separatorColor = self.menuSeparatorColor
        }
    }
    
    /// The text alignment of the menu item
    open var itemAlignment : AZDropdownMenuItemAlignment = .left {
        didSet {
            switch(itemAlignment) {
                case .right:
                    self.menuConfig?.itemAlignment = .right
                case .left:
                    self.menuConfig?.itemAlignment = .left
                case .center:
                    self.menuConfig?.itemAlignment = .center
            }
        }
    }
    
    /// The image position, default to .Prefix.  Image will be displayed after item's text if set to .Postfix
    open var itemImagePosition : AZDropdownMenuItemImagePosition = .prefix {
        didSet {
            switch(itemImagePosition) {
            case .prefix:
                self.menuConfig?.itemImagePosition = .prefix
            case .postfix:
                self.menuConfig?.itemImagePosition = .postfix
            }
        }
    }
    
    /// The image tintColor. Image will displayed in tintColor if drawed as a template image
    open var itemImageTintColor : UIColor = UIColor.black {
        didSet {
            self.menuConfig?.itemImageTintColor = itemImageTintColor
        }
    }
    
    fileprivate var calcMenuHeight : CGFloat {
        get {
            return CGFloat(itemHeight * itemDataSource.count)
        }
    }
    
    fileprivate var menuHeight : CGFloat {
        get {
            return (calcMenuHeight > frame.size.height) ? frame.size.height : calcMenuHeight
        }
    }
    
    fileprivate var itemDataSource : [AZDropdownMenuItemData] = []
    fileprivate var reuseId : String?
    fileprivate var menuConfig : AZDropdownMenuConfig?
    
    // MARK: - Initializer
    public init(titles:[String]) {
        self.isSetUpFinished = false
        self.titles = titles
        for title in titles {
            itemDataSource.append(AZDropdownMenuItemData(title: title))
        }
        self.menuConfig = AZDropdownMenuConfig()
        super.init(frame:UIScreen.main.bounds)
        self.accessibilityIdentifier = "AZDropdownMenu"
        self.backgroundColor = UIColor.clear
        self.alpha = 0.95
        self.translatesAutoresizingMaskIntoConstraints = false
        initOverlay()
        initMenu()
    }
    
    public init(dataSource:[AZDropdownMenuItemData]) {
        self.isSetUpFinished = false
        self.itemDataSource = dataSource
        self.menuConfig = AZDropdownMenuConfig()
        super.init(frame:UIScreen.main.bounds)
        self.accessibilityIdentifier = "AZDropdownMenu"
        self.backgroundColor = UIColor.clear
        self.alpha = 0.95;
        self.translatesAutoresizingMaskIntoConstraints = false
        initOverlay()
        initMenu()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    override open func layoutSubviews() {
        if isSetUpFinished == false {
            setupInitialLayout()
        }
    }

    fileprivate func initOverlay() {
        let frame = UIScreen.main.bounds
        overlay.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height)
        overlay.backgroundColor = self.overlayColor
        overlay.accessibilityIdentifier = "OVERLAY"
        overlay.alpha = 0
        overlay.isUserInteractionEnabled = true
        let touch : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AZDropdownMenu.overlayTapped))
        overlay.addGestureRecognizer(touch)
        addSubview(overlay)
    }

    fileprivate func initMenu() {
        let frame = UIScreen.main.bounds
        let menuFrame = CGRect(x: 0, y: 0, width: frame.size.width, height: menuHeight)

        menuView = UITableView(frame: menuFrame, style: .plain)
        menuView.isUserInteractionEnabled = true
        menuView.rowHeight = CGFloat(itemHeight)
        if self.reuseId == nil {
            self.reuseId = DROPDOWN_MENU_CELL_KEY
        }
        menuView.dataSource = self
        menuView.delegate = self
        menuView.isScrollEnabled = false
        menuView.accessibilityIdentifier = "MENU"
        menuView.separatorColor = menuConfig?.menuSeparatorColor
        addSubview(menuView)
    }

    fileprivate func setupInitialLayout() {

        let height = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIScreen.main.bounds.height)
        let width = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIScreen.main.bounds.width)

        addConstraints([height, width])
        isSetUpFinished = true
        
    }
    
    fileprivate func animateOvelay(_ alphaValue: CGFloat, interval: Double, completionHandler: (() -> Void)? ) {
        UIView.animate(
            withDuration: interval,
            animations: {
                self.overlay.alpha = alphaValue
            }, completion: { (finished: Bool) -> Void in
                if let completionHandler = completionHandler {
                    completionHandler()
                }
            }
        )
    }
    
    func overlayTapped() {
        hideMenu()
    }

    //MARK: - Public methods to control the menu
    
    /**
    Show menu
    
    - parameter view: The view to be attached by the menu, ex. the controller's view
    */
    open func showMenuFromView(_ view:UIView){
        
        view.addSubview(self)
        
        animateOvelay(overlayAlpha, interval: 0.4, completionHandler: nil)
        menuView.reloadData()
        self.delegate?.onOpenAZDropdownMenu(self)
        UIView.animate(
            withDuration: 0.2,
            delay:0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.6,
            options:[],
            animations:{
                self.frame.origin.y = view.frame.origin.y
                } , completion:{ (finished : Bool) -> Void in

                    self.delegate?.onOpenAZDropdownMenuFinished?(self)
            }
        )
    }
    
    open func hideMenu() {

        animateOvelay(0.0, interval: 0.1, completionHandler: nil)

        self.delegate?.onCloseAZDropdownMenu(self)
        UIView.animate(
            withDuration: 0.3, delay: 0.1,
            options: [],
            animations: {
                self.frame.origin.y = -1200
            },
            completion: { (finished: Bool) -> Void in
                self.removeFromSuperview()
                self.delegate?.onCloseAZDropdownMenuFinished?(self)
            }
        )
    }
}


// MARK: - UITableViewDataSource
extension AZDropdownMenu: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemDataSource.count
    }
    
    func getCellByData() -> AZDropdownMenuBaseCell? {
        if let _ = itemDataSource.first?.icon {
            return AZDropdownMenuDefaultCell(reuseIdentifier: DROPDOWN_MENU_CELL_KEY, config: self.menuConfig!)
        } else {
            return AZDropdownMenuBaseCell(style: .default, reuseIdentifier: DROPDOWN_MENU_CELL_KEY)
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = getCellByData() {
            let item = itemDataSource[(indexPath as NSIndexPath).row]
            if let config = self.menuConfig {
                cell.configureStyle(config)
            }
            cell.configureData(item)
            cell.layoutIfNeeded()
            return cell
        }
        return UITableViewCell()
    }

}


// MARK: - UITableViewDelegate
extension AZDropdownMenu: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated:true)
        cellTapHandler?(indexPath)
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.backgroundColor = itemSelectionColor
        }
        
        hideMenu()
    }
    
    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.backgroundColor = itemColor
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(itemHeight)
    }

}

struct AZDropdownMenuConfig {

    var itemColor : UIColor = UIColor.white
    var itemSelectionColor : UIColor = UIColor.lightGray
    var itemAlignment : AZDropdownMenuItemAlignment = .left
    var itemFontColor : UIColor = UIColor(red: 58/255, green: 58/255, blue: 58/255, alpha: 1.0)
    var itemFontSize : CGFloat = 14.0
    var itemFont : String = "Helvetica"
    var overlayAlpha : CGFloat = 0.5
    var overlayColor : UIColor = UIColor.black
    var menuSeparatorStyle : AZDropdownMenuSeperatorStyle = .singleline
    var menuSeparatorColor : UIColor = UIColor.lightGray
    var itemImagePosition : AZDropdownMenuItemImagePosition = .prefix
    var menuTopOffset: CGFloat = 0.0
    var itemImageTintColor : UIColor = UIColor.black
}


/**
 *  Menu's model object
 */
public struct AZDropdownMenuItemData {
    
    public let title:String
    public let icon:UIImage?
    
    public init(title:String){
        self.title = title
        self.icon = nil
    }
    
    public init(title:String, icon:UIImage) {
        self.title = title
        self.icon = icon
    }
}

/**
 The separator style of the menu
 
 - Singleline: A solid single line
 - None:       No Separator
 */
public enum AZDropdownMenuSeperatorStyle {
    case singleline, none
}

/**
 The position of image icon in the menu
 
 - Prefix:  Place icon before item title
 - Postfix: Place icon after item title
 */
public enum AZDropdownMenuItemImagePosition {
    case prefix, postfix
}
