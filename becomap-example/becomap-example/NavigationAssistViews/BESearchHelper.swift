//
//  BESearchHelper.swift
//  MapAssistView
//
//  Created by test on 24/10/19.
//  Copyright © 2019 GlobeCo Technologies Pvt Ltd. All rights reserved.
//

import Foundation
import UIKit
import becomap_ios

@objc public protocol BEMapAssistDelegate: NSObjectProtocol {
    func searchHelper(_ searchHelper: BESearchHelper, didRequestedforRoute points: [BCLocation])
    func searchHelper(_ searchHelper: BESearchHelper, didRequestedforResults text: String)
    func searchHelper(_ searchHelper: BESearchHelper, didSelectPoint point: BCLocation)
    func searchHelper(_ searchHelper: BESearchHelper, didRequestedToShowRouteOn floor: BCMapFloor)
    func didRequestedForPreview(_ searchHelper: BESearchHelper)
    func didRequestedForNavigation(_ searchHelper: BESearchHelper)
    func didReset(for searchHelper: BESearchHelper)
}

@objc public final class BESearchHelper: NSObject {
    var currentLocation: BCLocation?
    weak var delegate: BEMapAssistDelegate?
    private weak var parentViewController: UIViewController?
    private weak var view: UIView? {
        return parentViewController?.view
    }

    private lazy var searchListView: BESearchListView = { [weak self] in
        var searchList = BESearchListView()
        searchList.translatesAutoresizingMaskIntoConstraints = false
        searchList.isHidden = true
        return searchList
    }()

    private lazy var searchBar: BEMapSearchBar = { [weak self] in
        var searchView = BEMapSearchBar()
        searchView.translatesAutoresizingMaskIntoConstraints = false
        return searchView
    }()

    private lazy var navigationSearchBar: BENavSearchBar = { [weak self] in
        var searchView = BENavSearchBar()
        searchView.translatesAutoresizingMaskIntoConstraints = false
        searchView.isHidden = true
        return searchView
    }()

    private lazy var pointAssistView: BEPointAssistView = { [weak self] in
        var view = BEPointAssistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var navigationAssistView: BENavigationAssistView = { [weak self] in
        var view = BENavigationAssistView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var navigationInfoView: BENavigationInfoView = { [weak self] in
        var view = BENavigationInfoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    var navSearchBarHeight: CGFloat {
        let rowHeight = 48
        let supportViewHeight =
            (navigationSearchBar.pointsList.filter { $0 != nil }.count) >= 2 ? 50 : 0
        let minHight = CGFloat((2 * rowHeight) + 23)
        let maxHeight = CGFloat((3 * rowHeight) + 23 + 50 + (rowHeight / 2))
        let actualHeight = CGFloat(
            (navigationSearchBar.pointsList.count * rowHeight) + 23 + supportViewHeight
        )
        return actualHeight < minHight
            ? minHight : (actualHeight > maxHeight ? maxHeight : actualHeight)
    }

    private var navSearchBarHeightContrain: NSLayoutConstraint?

    /// searchIndex represents the index for point
    /// searchIndex -2: Not searching
    /// searchIndex -1: Normal Search
    /// searchIndex >= 0: Navigation Search, value represents the index
    private var searchIndex: Int = -2

    // MARK: - Initialization

    @objc public init(with parent: UIViewController) {
        parentViewController = parent
        super.init()
        setSearchHelperContrains()
        NotificationCenter.default.addObserver(
            self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    private func setSearchHelperContrains() {
        if let parentView = view {
            searchBar.delegate = self
            parentView.addSubview(searchBar)
            searchBar.topAnchor.constraint(equalTo: parentView.safeTopAnchor, constant: -44)
                .isActive = true
            searchBar.leadingAnchor.constraint(equalTo: parentView.safeLeadingAnchor).isActive =
                true
            searchBar.trailingAnchor.constraint(equalTo: parentView.safeTrailingAnchor).isActive =
                true
            searchBar.heightAnchor.constraint(equalToConstant: 107).isActive = true

            navigationSearchBar.delegate = self
            parentView.addSubview(navigationSearchBar)
            let leadingSpace = NSLayoutConstraint(
                item: navigationSearchBar, attribute: .leading, relatedBy: .equal,
                toItem: parentView, attribute: .leading, multiplier: 1.0, constant: 0
            )
            let trailingSpace = NSLayoutConstraint(
                item: navigationSearchBar, attribute: .trailing, relatedBy: .equal,
                toItem: parentView, attribute: .trailing, multiplier: 1.0, constant: 0
            )
            let topSpace = NSLayoutConstraint(
                item: navigationSearchBar, attribute: .top, relatedBy: .equal, toItem: parentView,
                attribute: .topMargin, multiplier: 1.0, constant: 0
            )
            navSearchBarHeightContrain = NSLayoutConstraint(
                item: navigationSearchBar, attribute: .height, relatedBy: .equal, toItem: nil,
                attribute: .notAnAttribute, multiplier: 1, constant: navSearchBarHeight
            )
            NSLayoutConstraint.activate([
                leadingSpace, trailingSpace, topSpace, navSearchBarHeightContrain!,
            ])

            searchListView.delegate = self
            parentView.addSubview(searchListView)
            searchListView.topAnchor.constraint(equalTo: searchBar.safeBottomAnchor).isActive = true
            searchListView.leadingAnchor.constraint(equalTo: parentView.safeLeadingAnchor)
                .isActive = true
            searchListView.trailingAnchor.constraint(equalTo: parentView.safeTrailingAnchor)
                .isActive = true
            searchListView.bottomAnchor.constraint(equalTo: parentView.safeBottomAnchor).isActive =
                true

            pointAssistView.delegate = self
            parentView.addSubview(pointAssistView)
            pointAssistView.bottomAnchor.constraint(equalTo: parentView.safeBottomAnchor).isActive =
                true
            pointAssistView.leadingAnchor.constraint(equalTo: parentView.safeLeadingAnchor)
                .isActive = true
            pointAssistView.trailingAnchor.constraint(equalTo: parentView.safeTrailingAnchor)
                .isActive = true
            pointAssistView.heightAnchor.constraint(equalToConstant: 140).isActive = true

            navigationAssistView.delegate = self
            parentView.addSubview(navigationAssistView)
            navigationAssistView.bottomAnchor.constraint(equalTo: parentView.safeBottomAnchor)
                .isActive = true
            navigationAssistView.leadingAnchor.constraint(equalTo: parentView.safeLeadingAnchor)
                .isActive = true
            navigationAssistView.trailingAnchor.constraint(equalTo: parentView.safeTrailingAnchor)
                .isActive = true
            navigationAssistView.heightAnchor.constraint(equalToConstant: 140).isActive = true

            navigationInfoView.delegate = self
            parentView.addSubview(navigationInfoView)
            navigationInfoView.topAnchor.constraint(equalTo: parentView.safeTopAnchor).isActive =
                true
            navigationInfoView.leadingAnchor.constraint(equalTo: parentView.safeLeadingAnchor)
                .isActive = true
            navigationInfoView.trailingAnchor.constraint(equalTo: parentView.safeTrailingAnchor)
                .isActive = true
            navigationInfoView.heightAnchor.constraint(equalToConstant: 170).isActive = true
        }
    }

    deinit {
        print("Search helper deinit")
    }

    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {}
        if UIDevice.current.orientation.isPortrait {}
    }

    // MARK: - Access Methods

    @objc public func selectPoint(point: BCLocation) {
        showSearchBar(with: point)
        showPointAssistView(point: point)
        searchListView.hideView()
        navigationSearchBar.hideView()
        navigationSearchBar.cancelSearch()
        navigationAssistView.hideView()
        navigationInfoView.hideView()
        delegate?.searchHelper(self, didSelectPoint: point)
    }

    @objc public func updateSearchList(points: [BCLocation]) {
        searchListView.loadPointsList(points: points)
    }

    @objc public func didPlotRouteWith(points: [BCLocation], floorList: [BCMapFloor]) {
        showNavigationAssistView(routePoints: points, floorList: floorList)
    }

    @objc public func resetScreen() {
        searchIndex = -2
        showSearchBar()
        searchListView.hideView()
        navigationSearchBar.hideView()
        navigationSearchBar.cancelSearch()
        pointAssistView.hideView()
        navigationAssistView.hideView()
        navigationInfoView.hideView()
        delegate?.didReset(for: self)
    }

    @objc public func clearScreen() {
        searchBar.hideView()
        searchListView.hideView()
        navigationSearchBar.hideView()
        pointAssistView.hideView()
        navigationAssistView.hideView()
        navigationInfoView.hideView()
    }

    @objc public func showNavigationOption(points: [BCLocation]) {
        showNavigationInforViewWith(points: points)
    }
}

extension BESearchHelper: BESearchBarDelegate {
    @objc public func showSearchBar(with point: BCLocation? = nil, editingEnabled: Bool = false) {
        searchBar.showView()
        searchBar.setPoint(point: point)
        if editingEnabled {
            showSearchList()
        } else {
            hideSearchList()
        }
    }

    func searchBar(_: BEMapSearchBar, searchFieldDidChangeCarecter string: String) {
        delegate?.searchHelper(self, didRequestedforResults: string)
    }

    func searchBarDidBeginEditing(_: BEMapSearchBar) {
        showSearchList()
    }

    func searchBarDidEndEditing(_: BEMapSearchBar) {
        hideSearchList()
        if searchIndex >= 0 {
            showNavigationBar()
        } else {
            showSearchBar()
        }
    }

    func searchBarShouldNavigate(_: BEMapSearchBar) {
        showNavigationBar()
    }

    func searchBarDidClear(_: BEMapSearchBar) {
        if searchIndex < 0 {
            pointAssistView.hideView()
        }
        // Call resetScreen to clear the currently selected point
        resetScreen()
    }
}

extension BESearchHelper: BENavSearchBarDelegate {
    @objc public func showNavigationBar(destination: BCLocation? = nil) {
        navigationSearchBar.showView()
        if destination != nil {
            navigationSearchBar.addPointAtIndex(
                index: navigationSearchBar.pointsList.count - 1, point: destination
            )
        }
        if navigationSearchBar.pointsList[0] == nil {
            navigationSearchBar.addPointAtIndex(index: 0, point: currentLocation)
        }
    }

    @objc public func showNavigationBarWith(points: [BCLocation] = []) {
        navigationSearchBar.setPoints(routePoints: points)
        navigationSearchBar.showView()
        setNavigationSearchBarHeight()
    }

    private func setNavigationSearchBarHeight() {
        UIView.animate(
            withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn,
            animations: {
                self.navSearchBarHeightContrain?.constant = self.navSearchBarHeight
                self.navigationSearchBar.layoutIfNeeded()
            }, completion: nil
        )
    }

    private func requestForReroute() {
        let finalList = navigationSearchBar.pointsList.filter { $0 != nil }
        if finalList.count > 1 {
            delegate?.searchHelper(self, didRequestedforRoute: finalList as! [BCLocation])
        }
    }

    // MARK: - BENavSearchBarDelegate

    func navSearchBar(_: BENavSearchBar, didAdd point: BCLocation?, at _: Int) {
        setNavigationSearchBarHeight()
        if point != nil {
            requestForReroute()
        }
    }

    func navSearchBar(_: BENavSearchBar, didRemove point: BCLocation?, at _: Int) {
        setNavigationSearchBarHeight()
        if point != nil {
            requestForReroute()
        }
    }

    func navSearchBar(_: BENavSearchBar, didChangedOrder _: [BCLocation]) {
        requestForReroute()
    }

    func navSearchBar(_: BENavSearchBar, didCompleteSearch points: [BCLocation]) {
        navigationSearchBar.hideView()
        showNavigationInforViewWith(points: points)
        setNavigationSearchBarHeight()
    }

    func navSearchBar(_: BENavSearchBar, didRequestedForSearchFor index: Int) {
        navigationSearchBar.hideView()
        if let point = navigationSearchBar.pointsList[index] {
            showSearchBar(with: point, editingEnabled: true)
        } else {
            showSearchBar(editingEnabled: true)
        }
        searchIndex = index
    }

    func didCanceledSearch(for _: BENavSearchBar) {
        resetScreen()
        setNavigationSearchBarHeight()
    }
}

extension BESearchHelper: BESearchListDelegate {
    // MARK: - BESearchListDelegate

    func searchlist(_: BESearchListView, didLoad _: [BCLocation]) {
        // print("Did load search BESearchListView")
    }

    func searchlist(_: BESearchListView, didSelected point: BCLocation) {
        if searchIndex >= 0 {
            showNavigationBar()
            navigationSearchBar.addPointAtIndex(index: searchIndex, point: point)
        } else {
            selectPoint(point: point)
        }
        hideSearchList()
    }

    private func showSearchList() {
        searchListView.showView()
        searchBar.enableSearchMode()
    }

    private func hideSearchList() {
        searchListView.hideView()
        searchBar.disableSearchMode()
    }
}

extension BESearchHelper: BEPointAssistDelegate {
    private func showPointAssistView(point: BCLocation) {
        pointAssistView.show()
        navigationAssistView.hide()
        pointAssistView.setPoint(point: point)
    }

    // MARK: - BEPointAssistDelegate

    func pointAssist(_: BEPointAssistView, didRequestedForDirectionTo point: BCLocation) {
        showNavigationBar(destination: point)
        navigationInfoView.hideView()
        pointAssistView.hideView()
    }

    func pointAssistDidCancel(_: BEPointAssistView) {
        resetScreen()
    }
}

extension BESearchHelper: BENavigationAssistDelegate {
    private func showNavigationAssistView(routePoints: [BCLocation], floorList: [BCMapFloor]) {
        pointAssistView.hideView()
        navigationAssistView.show()
        navigationAssistView.setRouteWith(
            routePoints: routePoints, floorList: floorList,
            navigationEnabled: currentLocation != nil
        )
    }

    // MARK: - BENavigationAssistDelegate

    func navigationAssistDidCancel(_: BENavigationAssistView) {
        resetScreen()
    }

    func navigationAssistDidRequestedForNavigation(_: BENavigationAssistView) {
        delegate?.didRequestedForNavigation(self)
        navigationAssistView.hide()
    }

    func navigationAssistDidRequestedForPreview(_: BENavigationAssistView) {
        delegate?.didRequestedForPreview(self)
        navigationAssistView.hide()
    }

    func navigationAssist(
        _: BENavigationAssistView, didRequestedToShowRouteOn floor: BCMapFloor
    ) {
        delegate?.searchHelper(self, didRequestedToShowRouteOn: floor)
    }
}

extension BESearchHelper: BENavigationInfoViewDelegate {
    func showNavigationInforViewWith(points: [BCLocation]) {
        navigationInfoView.setRouteWith(routePoints: points)
        navigationInfoView.showView()
    }

    // MARK: - BENavigationInfoViewDelegate

    func navInfoView(
        _: BENavigationInfoView, didRequestedForEditWith points: [BCLocation]
    ) {
        showNavigationBarWith(points: points)
        navigationInfoView.hideView()
    }

    func didCancelednavigation(for _: BENavigationInfoView) {
        resetScreen()
    }
}
