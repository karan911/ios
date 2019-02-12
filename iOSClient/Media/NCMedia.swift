//
//  NCMedia.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 12/02/2019.
//  Copyright © 2018 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import Sheeeeeeeeet

class NCMedia: UIViewController ,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, NCListCellDelegate, NCGridCellDelegate, NCSectionHeaderMenuDelegate, DropdownMenuDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate  {
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
   
    private var metadataPush: tableMetadata?
    private var isEditMode = false
    private var selectFileID = [String]()
    
    private var filterTypeFileImage = false;
    private var filterTypeFileVideo = false;
    
    private var sectionDatasource = CCSectionDataSourceMetadata()
    
    private var typeLayout = k_layout_grid
    
    private var autoUploadFileName = ""
    private var autoUploadDirectory = ""
    
    private var listLayout: NCListLayout!
    private var gridLayout: NCGridLayout!
    
    private var actionSheet: ActionSheet?
    
    private let headerMenuHeight: CGFloat = 50
    private let sectionHeaderHeight: CGFloat = 20
    private let footerHeight: CGFloat = 50

    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Cell
        collectionView.register(UINib.init(nibName: "NCListCell", bundle: nil), forCellWithReuseIdentifier: "listCell")
        collectionView.register(UINib.init(nibName: "NCGridCell", bundle: nil), forCellWithReuseIdentifier: "gridCell")
        
        // Header
        collectionView.register(UINib.init(nibName: "NCSectionHeaderMenu", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeaderMenu")
        collectionView.register(UINib.init(nibName: "NCSectionHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        // Footer
        collectionView.register(UINib.init(nibName: "NCSectionFooter", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "sectionFooter")
        
        collectionView.alwaysBounceVertical = true

        listLayout = NCListLayout()
        gridLayout = NCGridLayout()
        
        // Add Refresh Control
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        
        // Configure Refresh Control
        refreshControl.tintColor = NCBrandColor.sharedInstance.brandText
        refreshControl.backgroundColor = NCBrandColor.sharedInstance.brand
        refreshControl.addTarget(self, action: #selector(loadDatasource), for: .valueChanged)
        
        // empty Data Source
        self.collectionView.emptyDataSetDelegate = self;
        self.collectionView.emptyDataSetSource = self;        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Color
        appDelegate.aspectNavigationControllerBar(self.navigationController?.navigationBar, online: appDelegate.reachability.isReachable(), hidden: false)
        appDelegate.aspectTabBar(self.tabBarController?.tabBar, hidden: false)
        
        self.navigationItem.title = NSLocalizedString("_media_", comment: "")
        
        // get auto upload folder
        autoUploadFileName = NCManageDatabase.sharedInstance.getAccountAutoUploadFileName()
        autoUploadDirectory = NCManageDatabase.sharedInstance.getAccountAutoUploadDirectory(appDelegate.activeUrl)
        
        if typeLayout == k_layout_list {
            collectionView.collectionViewLayout = listLayout
        } else {
            collectionView.collectionViewLayout = gridLayout
        }
        
        loadDatasource()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.actionSheet?.viewDidLayoutSubviews()
        }
    }
    
    // MARK: DZNEmpty
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return NCBrandColor.sharedInstance.backgroundView
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return CCGraphics.changeThemingColorImage(UIImage.init(named: "filesNoFiles"), multiplier: 2, color: NCBrandColor.sharedInstance.brandElement)
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let text = "\n"+NSLocalizedString("_files_no_files_", comment: "")
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        return NSAttributedString.init(string: text, attributes: attributes)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    // MARK: TAP EVENT
    
    func tapSwitchHeader(sender: Any) {
        
        if collectionView.collectionViewLayout == gridLayout {
            // list layout
            UIView.animate(withDuration: 0.0, animations: {
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(self.listLayout, animated: false, completion: { (_) in
                    self.collectionView.reloadData()
                    self.collectionView.setContentOffset(CGPoint(x:0,y:0), animated: false)
                })
            })
            typeLayout = k_layout_list
        } else {
            // grid layout
            UIView.animate(withDuration: 0.0, animations: {
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.setCollectionViewLayout(self.gridLayout, animated: false, completion: { (_) in
                    self.collectionView.reloadData()
                    self.collectionView.setContentOffset(CGPoint(x:0,y:0), animated: false)
                })
            })
            typeLayout = k_layout_grid
        }
    }
    
    func tapOrderHeader(sender: Any) {
    
    }
    
    func tapMoreHeader(sender: Any) {
        
    }
    
    func tapMoreListItem(with fileID: String, sender: Any) {
        tapMoreGridItem(with: fileID, sender: sender)
    }
    
    func tapMoreGridItem(with fileID: String, sender: Any) {
        
        guard let metadata = NCManageDatabase.sharedInstance.getMetadata(predicate: NSPredicate(format: "fileID == %@", fileID)) else {
            return
        }
        
        if !isEditMode {
            
            var items = [ActionSheetItem]()
            let appearanceDelete = ActionSheetItemAppearance.init()
            appearanceDelete.textColor = UIColor.red
            
            // 0 == CCMore, 1 = first NCOffline ....
            if (self == self.navigationController?.viewControllers[1]) {
                items.append(ActionSheetItem(title: NSLocalizedString("_remove_available_offline_", comment: ""), value: 0, image: CCGraphics.changeThemingColorImage(UIImage.init(named: "offline"), multiplier: 2, color: NCBrandColor.sharedInstance.icon)))
            }
            items.append(ActionSheetItem(title: NSLocalizedString("_share_", comment: ""), value: 1, image: CCGraphics.changeThemingColorImage(UIImage.init(named: "share"), multiplier: 2, color: NCBrandColor.sharedInstance.icon)))

            let itemDelete = ActionSheetItem(title: NSLocalizedString("_delete_", comment: ""), value: 2, image: CCGraphics.changeThemingColorImage(UIImage.init(named: "trash"), multiplier: 2, color: UIColor.red))
            itemDelete.customAppearance = appearanceDelete
            items.append(itemDelete)
            items.append(ActionSheetCancelButton(title: NSLocalizedString("_cancel_", comment: "")))
            
            actionSheet = ActionSheet(items: items) { sheet, item in
                if item.value as? Int == 0 {
                    if metadata.directory {
                        NCManageDatabase.sharedInstance.setDirectory(serverUrl: CCUtility.stringAppendServerUrl(metadata.serverUrl, addFileName: metadata.fileName)!, offline: false, account: self.appDelegate.activeAccount)
                    } else {
                        NCManageDatabase.sharedInstance.setLocalFile(fileID: metadata.fileID, offline: false)
                    }
                    self.loadDatasource()
                }
                if item.value as? Int == 1 { self.appDelegate.activeMain.readShare(withAccount: self.appDelegate.activeAccount, openWindow: true, metadata: metadata) }
                if item.value as? Int == 2 { self.deleteItem(with: metadata, sender: sender) }
                if item is ActionSheetCancelButton { print("Cancel buttons has the value `true`") }
            }
            
            let headerView = NCActionSheetHeader.sharedInstance.actionSheetHeader(isDirectory: metadata.directory, iconName: metadata.iconName, fileID: metadata.fileID, fileNameView: metadata.fileNameView, text: metadata.fileNameView)
            actionSheet?.headerView = headerView
            actionSheet?.headerView?.frame.size.height = 50
            
            actionSheet?.present(in: self, from: sender as! UIButton)
        } else {
            
            let buttonPosition:CGPoint = (sender as! UIButton).convert(CGPoint.zero, to:collectionView)
            let indexPath = collectionView.indexPathForItem(at: buttonPosition)
            collectionView(self.collectionView, didSelectItemAt: indexPath!)
        }
    }
    
    // MARK: DROP-DOWN-MENU

    func dropdownMenu(_ dropdownMenu: DropdownMenu, didSelectRowAt indexPath: IndexPath) {
        
        if dropdownMenu.token == "tapMoreHeaderMenu" {
        
        }
        
        if dropdownMenu.token == "tapMoreHeaderMenuSelect" {
            
        }
    }
    
    // MARK: NC API
    
    func deleteItem(with metadata: tableMetadata, sender: Any) {
        
        var items = [ActionSheetItem]()
        
        guard let tableDirectory = NCManageDatabase.sharedInstance.getTableDirectory(predicate: NSPredicate(format: "account == %@ AND serverUrl == serverUrl", appDelegate.activeAccount, metadata.serverUrl)) else {
            return
        }
        
        items.append(ActionSheetDangerButton(title: NSLocalizedString("_delete_", comment: "")))
        items.append(ActionSheetCancelButton(title: NSLocalizedString("_cancel_", comment: "")))
        
        actionSheet = ActionSheet(items: items) { sheet, item in
            if item is ActionSheetDangerButton {
                NCMainCommon.sharedInstance.deleteFile(metadatas: [metadata], e2ee: tableDirectory.e2eEncrypted, serverUrl: tableDirectory.serverUrl, folderFileID: tableDirectory.fileID) { (errorCode, message) in
                    self.loadDatasource()
                }
            }
            if item is ActionSheetCancelButton { print("Cancel buttons has the value `true`") }
        }
        
        let headerView = NCActionSheetHeader.sharedInstance.actionSheetHeader(isDirectory: metadata.directory, iconName: metadata.iconName, fileID: metadata.fileID, fileNameView: metadata.fileNameView, text: metadata.fileNameView)
        actionSheet?.headerView = headerView
        actionSheet?.headerView?.frame.size.height = 50
        
        actionSheet?.present(in: self, from: sender as! UIButton)
    }
    
    // MARK: DATASOURCE
    @objc func loadDatasource() {
        
        if appDelegate.activeAccount.count == 0 {
            return
        }
        
        let startDirectory = NCManageDatabase.sharedInstance.getAccountStartDirectoryMediaTabView(CCUtility.getHomeServerUrlActiveUrl(appDelegate.activeUrl))
        let date = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        
        OCNetworking.sharedManager()?.search(withAccount: appDelegate.activeAccount, fileName: "", serverUrl: startDirectory, contentType: ["image/%", "video/%"], date: date, depth: "infinity", completion: { (account, metadatas, message, errorCode) in
            
            if errorCode == 0 && account == self.appDelegate.activeAccount {
                NCManageDatabase.sharedInstance.createTablePhotos(metadatas as! [tableMetadata], account: account!)
                
                self.sectionDatasource = CCSectionMetadata.creataDataSourseSectionMetadata(metadatas, listProgressMetadata: nil, groupByField: "date", filterFileID: nil, filterTypeFileImage: self.filterTypeFileImage, filterTypeFileVideo: self.filterTypeFileVideo, activeAccount: account!)
                self.collectionView.reloadData()

            }
        })
                
        self.refreshControl.endRefreshing()
    }
    
    // MARK: COLLECTIONVIEW METHODS
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (indexPath.section == 0) {
            
            if kind == UICollectionView.elementKindSectionHeader {
                
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderMenu", for: indexPath) as! NCSectionHeaderMenu
                
                if collectionView.collectionViewLayout == gridLayout {
                    header.buttonSwitch.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "switchList"), multiplier: 2, color: NCBrandColor.sharedInstance.icon), for: .normal)
                } else {
                    header.buttonSwitch.setImage(CCGraphics.changeThemingColorImage(UIImage.init(named: "switchGrid"), multiplier: 2, color: NCBrandColor.sharedInstance.icon), for: .normal)
                }
                
                header.delegate = self
                
                header.setStatusButton(count: sectionDatasource.allFileID.count)
                
                header.buttonOrder.isHidden = true
                header.labelSection.isHidden = false
                header.buttonMore.isHidden = false
                
                header.setTitleLabel(sectionDatasource: sectionDatasource, section: indexPath.section)
                header.labelSectionHeightConstraint.constant = sectionHeaderHeight
                
                return header
            
            } else {
                
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath) as! NCSectionFooter
                
                footer.setTitleLabel(sectionDatasource: sectionDatasource)
                
                return footer
            }
            
        } else {
        
            if kind == UICollectionView.elementKindSectionHeader {
                
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as! NCSectionHeader
                
                header.setTitleLabel(sectionDatasource: sectionDatasource, section: indexPath.section)
                
                return header
                
            } else {
                
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath) as! NCSectionFooter
                
                footer.setTitleLabel(sectionDatasource: sectionDatasource)

                return footer
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.frame.width, height: headerMenuHeight + sectionHeaderHeight)
        } else {
            return CGSize(width: collectionView.frame.width, height: sectionHeaderHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let sections = sectionDatasource.sectionArrayRow.allKeys.count
        if (section == sections - 1) {
            return CGSize(width: collectionView.frame.width, height: footerHeight)
        } else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = sectionDatasource.sectionArrayRow.allKeys.count
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = sectionDatasource.sections.object(at: section)
        let datasource = sectionDatasource.sectionArrayRow.object(forKey: key) as! [tableMetadata]
        return datasource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let metadata = NCMainCommon.sharedInstance.getMetadataFromSectionDataSourceIndexPath(indexPath, sectionDataSource: sectionDatasource) else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as! NCListCell
        }
        
        let cell = NCMainCommon.sharedInstance.collectionViewCellForItemAt(indexPath, collectionView: collectionView, typeLayout: typeLayout, metadata: metadata, metadataFolder: nil, serverUrl: metadata.serverUrl, isEditMode: isEditMode, selectFileID: selectFileID, autoUploadFileName: autoUploadFileName, autoUploadDirectory: autoUploadDirectory, hideButtonMore: false, source: self)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let metadata = NCMainCommon.sharedInstance.getMetadataFromSectionDataSourceIndexPath(indexPath, sectionDataSource: sectionDatasource) else {
            return
        }
        metadataPush = metadata
        
        if isEditMode {
            if let index = selectFileID.index(of: metadata.fileID) {
                selectFileID.remove(at: index)
            } else {
                selectFileID.append(metadata.fileID)
            }
            collectionView.reloadItems(at: [indexPath])
            return
        }
        
        performSegue(withIdentifier: "segueDetail", sender: self)
    }
    
    // MARK: SEGUE
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let photoDataSource: NSMutableArray = []
        
        for fileID: String in sectionDatasource.allFileID as! [String] {
            let metadata = sectionDatasource.allRecordsDataSource.object(forKey: fileID) as! tableMetadata
            if metadata.typeFile == k_metadataTypeFile_image {
                photoDataSource.add(metadata)
            }
        }
        
        if let segueNavigationController = segue.destination as? UINavigationController {
            if let segueViewController = segueNavigationController.topViewController as? CCDetail {
            
                segueViewController.metadataDetail = metadataPush
                segueViewController.dateFilterQuery = nil
                segueViewController.photoDataSource = photoDataSource
                segueViewController.title = metadataPush!.fileNameView
            }
        }
    }
}