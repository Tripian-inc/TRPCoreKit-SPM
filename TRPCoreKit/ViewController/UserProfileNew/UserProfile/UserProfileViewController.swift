//
//  UserProfileViewController.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-04-19.
//

import UIKit
import WebKit

class UserProfileViewController: TRPBaseUIViewController {
    
    @IBOutlet weak var userNameLbl: UILabel!
    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var travelSubTitle: ProfileSubTitle!
    @IBOutlet weak var accountSettings: ProfileSubTitle!
    @IBOutlet weak var supportSubTitle: ProfileSubTitle!
    @IBOutlet weak var tripBtn: ProfileImageButton!
    @IBOutlet weak var travelCompaninBtn: ProfileImageButton!
    @IBOutlet weak var personalInformationBtn: ProfileImageButton!
    @IBOutlet weak var notificationBtn: ProfileImageButton!
    @IBOutlet weak var offersHistoryBtn: ProfileImageButton!
    @IBOutlet weak var termsOfUseBtn: ProfileImageButton!
    @IBOutlet weak var privacyPolicyBtn: ProfileImageButton!
    @IBOutlet weak var aboutTripianBtn: ProfileImageButton!
    @IBOutlet weak var editProfileBtn: UIButton!
    @IBOutlet weak var logOutBtn: UIButton!
    @IBOutlet weak var deleteUserBtn: UIButton!
    @IBOutlet weak var tradeMarkLbl: UILabel!
    @IBOutlet weak var versionLbl: UILabel!
    var viewModel: UserProfileViewModel!
    weak var userProfileDelegate: UserProfileViewControllerDelegate?
    
    private var container: UIView?
    private var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBackButton(position: .left)
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.start()
    }
   
    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func editProfileClicked(_ sender: Any) {
    }
  
    @IBAction func logOutClicked(_ sender: Any) {
        viewModel.logOut()
    }
}
extension UserProfileViewController {
    private func setupUI() {
        setupHeader()
        setupSubTitle()
        setupSubButtons()
        setupTrademarkLbl()
        setupVersionLbl()
    }
    
    private func setupHeader() {
        userNameLbl.font = trpTheme.font.display
        userNameLbl.textColor = trpTheme.color.tripianBlack
        
//        cityLbl.font = appTheme.font.body2
//        cityLbl.textColor = appTheme.color.textBody
//        cityLbl.text = "Istanbul"
        cityLbl.isHidden = true
        let editProfileImage = UIImage(named: "btn_edit_default")?.withRenderingMode(.alwaysOriginal)
        editProfileBtn.setImage(editProfileImage, for: .normal)
        editProfileBtn.isHidden = true
    }
    
    private func setupSubTitle() {
        travelSubTitle.label.text = "Travel"
        accountSettings.label.text = "Account Settings"
        supportSubTitle.label.text = "Support"
    }
    
    private func setupSubButtons(){
        tripBtn.iconImageView.image = UIImage(named: "icon_direction")
        tripBtn.label.text = "Trips"
        
//        travelCompaninBtn.iconImageView.image = UIImage(named: "icon_companion")
        travelCompaninBtn.iconImageView.removeFromSuperview()
        travelCompaninBtn.label.text = "Travel Companions"
        travelCompaninBtn.button.addTarget(self, action: #selector(companionAction), for: .touchUpInside)
        
//        personalInformationBtn.iconImageView.image = UIImage(named: "icon_person")
        personalInformationBtn.iconImageView.removeFromSuperview()
        personalInformationBtn.label.text = "Profile"
        personalInformationBtn.button.addTarget(self, action: #selector(personalInformationAction), for: .touchUpInside)
        
        termsOfUseBtn.iconImageView.removeFromSuperview()
        termsOfUseBtn.label.text = "Terms of Use"
        termsOfUseBtn.button.addTarget(self, action: #selector(termsOfUseAction), for: .touchUpInside)
        
        privacyPolicyBtn.iconImageView.removeFromSuperview()
        privacyPolicyBtn.label.text = "Privacy Policy"
        privacyPolicyBtn.button.addTarget(self, action: #selector(privacyPolicyAction), for: .touchUpInside)
        
        aboutTripianBtn.iconImageView.removeFromSuperview()
        aboutTripianBtn.label.text = "About Tripian"
        aboutTripianBtn.button.addTarget(self, action: #selector(aboutTripianAction), for: .touchUpInside)
        
        logOutBtn.setTitle("Logout", for: .normal)
        logOutBtn.titleLabel?.font = trpTheme.font.header2
        logOutBtn.setTitleColor(trpTheme.color.tripianPrimary, for: .normal)
    }
    
    private func setupTrademarkLbl() {
        tradeMarkLbl.font = trpTheme.font.body3
        tradeMarkLbl.textColor = trpTheme.color.tripianBlack
        tradeMarkLbl.text = "Feel like a local wherever you go ™"
    }
    
    private func setupVersionLbl() {
        versionLbl.font = trpTheme.font.body3
        versionLbl.textColor = trpTheme.color.tripianBlack
        versionLbl.text = "Version \(Bundle.main.releaseVersionNumber ?? "")+\(Bundle.main.buildVersionNumber ?? "")"
    }
    
    private func showPopUp(url: String) {
        let popupWebView = PopupWebView()
        popupWebView.btnAction  = {
            popupWebView.closeView()
        }
        popupWebView.show(url: url)
    }
    
    @objc func companionAction(_ sender: UIButton) {
        self.userProfileDelegate?.userProfileHandle(.companion)
    }
    
    @objc func personalInformationAction(_ sender: UIButton) {
        self.userProfileDelegate?.userProfileHandle(.personalInfo)
    }
    
    @objc func termsOfUseAction(_ sender: UIButton) {
        self.showPopUp(url: "https://www.tripian.com/docs/l/tos.html")
    }
    
    @objc func privacyPolicyAction(_ sender: UIButton) {
        self.showPopUp(url: "https://www.tripian.com/docs/l/pp.html")
    }
    
    @objc func aboutTripianAction(_ sender: UIButton) {
        guard let url = URL(string: "https://www.tripian.com/about.html") else { return }
        UIApplication.shared.open(url)
    }
}

extension UserProfileViewController:  UserProfileViewModelDelegate {
    
    func handleViewModelOutput(_ output: UserProfileViewModelOutput) {
        switch output {
        case .showError(let error):
            showError(error)
        case .showLoading(let load):
            showLoader(load)
        case .userName(let name):
            userNameLbl.text = name
        case .logOut:
            self.handleLogout()
        }
    }
    
    private func handleLogout() {
        self.userProfileDelegate?.userProfileHandle(.logOut)
    }
}
