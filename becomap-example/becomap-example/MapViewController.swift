//
//  MapViewController.swift
//  becomap-serve
//
//  Created by Mithin on 18/06/25.
//

import UIKit
import becomap_ios

class MapViewController: UIViewController {
    var site: BCSite?
    var mapView: BCMapView!
    var myview: UIView = .init()
    var mapPoints: [String: BCLocation] = [:]
    var routePoints: [BCLocation] = []
    var routeFloors: [BCLocation] = []
    var routeSegments: [BCRouteSegment] = []

    var serchHelper: BESearchHelper?
    var floorSwitcher: BEFloorSwitcher!

    // Track currently selected point
    private var currentlySelectedPoint: BCLocation?

    // Flag to prevent circular calls between map view and search helper
    private var isProcessingLocationSelection = false

    // Expose mapView for sharing with other view controllers
    var sharedMapView: BCMapView {
        return mapView
    }

    // Delegate for events view controller
    weak var eventsDelegate: EventsViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        addMapView()

        serchHelper = BESearchHelper(with: self)
        serchHelper?.delegate = self
        mapView.delegate = self
        mapView.renderSiteWith(
            clientId: "XXXXXXX",
            clientSecret: "XXXXX",
            siteId: "XXXXX"
        )
    }

    func addMapView() {
        myview = UIView(
            frame: CGRect(
                x: 0, y: 0, width: UIScreen.main.bounds.size.width,
                height: UIScreen.main.bounds.size.height
            )
        )
        myview.backgroundColor = .green
        view.addSubview(myview)
        myview.translatesAutoresizingMaskIntoConstraints = false
        myview.bottomAnchor.constraint(equalTo: view.safeBottomAnchor).isActive = true
        myview.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor).isActive = true
        myview.topAnchor.constraint(equalTo: view.safeTopAnchor).isActive = true
        myview.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor).isActive = true

        mapView = BCMapView(
            frame: CGRect(
                x: 0, y: 0, width: myview.frame.size.width, height: myview.bounds.size.height - 20
            )
        )
        mapView.backgroundColor = .black
        myview.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.bottomAnchor.constraint(equalTo: myview.safeBottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: myview.safeLeadingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: myview.safeTopAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: myview.safeTrailingAnchor).isActive = true

        // Add Floor Switcher
        addFloorSwitcher()
    }

    /**
     * Adds the floor switcher UI component to the view.
     *
     * The floor switcher is positioned at the bottom-left of the screen and allows
     * users to switch between different floors in the building. It integrates with
     * the map view to synchronize floor selection.
     */
    private func addFloorSwitcher() {
        floorSwitcher = BEFloorSwitcher()
        floorSwitcher.delegate = self
        view.addSubview(floorSwitcher)

        floorSwitcher.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floorSwitcher.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 16),
            floorSwitcher.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -16),
            floorSwitcher.widthAnchor.constraint(equalToConstant: 200),
        ])
    }

    private func setupFloorSwitcher() {
        guard let site = site else { return }
        var allFloors: [BCMapFloor] = []
        for building in site.buildings {
            if let floors = building.floors {
                allFloors.append(contentsOf: floors)
            }
        }
        print(allFloors.map { $0.shortName })
        floorSwitcher.setFloors(allFloors)

        // Set viewport for the first floor (or default floor) if available
        if let firstFloor = allFloors.first {
            if let viewPort = firstFloor.viewPort {
                print(
                    "🏢 FloorSwitcher: Setting initial viewport for floor - \(firstFloor.name ?? "Unknown")"
                )
                print("   - Zoom: \(viewPort.zoom ?? 18)")
                print("   - Pitch: \(viewPort.pitch ?? 0)")
                print("   - Bearing: \(viewPort.bearing ?? 0)")
                print("   - Center: \(viewPort.center ?? [])")

                mapView.setViewport(newOptions: viewPort)
            } else {
                print(
                    "🏢 FloorSwitcher: No viewport options available for initial floor - \(firstFloor.name ?? "Unknown")"
                )
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    deinit {
        print("MapViewContriller deinit")
    }
}

extension MapViewController: BCMapViewDelegate {
    // MARK: - Map Events

    func mapView(_: BCMapView, didRenderSite site: BCSite) {
        print("🎯 MapView: didRenderSite - \(site.siteName ?? "Unknown")")
        self.site = site
    }

    func mapView(_ mapView: BCMapView, didLoadData success: Bool) {
        print("📦 MapView: didLoadData - success: \(success)")
        setupFloorSwitcher()
        guard success else {
            print("❌ MapView: Cache population failed")
            return
        }

        // Use synchronous cache methods to access data immediately
        let locations = mapView.getLocations()
        let categories = mapView.getCategories()
        let amenities = mapView.getAmenityLocations()
        let amenityTypes = mapView.getAmenityTypes()

        // Get happenings by type
        let offers = mapView.getHappenings(type: .offer)
        let news = mapView.getHappenings(type: .news)
        let events = mapView.getHappenings(type: .event)
        let allHappenings = offers + news + events

        print("📦 MapView: Cache loaded successfully:")
        print("   - \(locations.count) locations")
        print("   - \(categories.count) categories")
        print("   - \(amenities.count) amenities")
        print("   - \(amenityTypes.count) amenity types")
        print(
            "   - \(allHappenings.count) happenings (offers: \(offers.count), news: \(news.count), events: \(events.count))"
        )

        // Store locations in mapPoints dictionary for existing functionality
        for location in locations {
            if let id = location.id {
                mapPoints[id] = location
            }
        }

        // Forward happenings to EventsViewController if delegate is set
        if !allHappenings.isEmpty {
            eventsDelegate?.didReceiveHappenings(allHappenings)
        }
    }

    func mapView(_: BCMapView, didChangeView _: Any) {
        // print("🔄 MapView: View changed - \(payload)")
    }

    func mapView(_: BCMapView, didSelectLocation location: BCLocation) {
        print("🎯 MapView: Location selected - \(location.name ?? "Unknown")")

        // Prevent circular calls between map view and search helper
        guard !isProcessingLocationSelection else {
            print("🎯 MapView: Skipping location selection - already processing")
            return
        }

        if currentlySelectedPoint?.id != location.id {
            isProcessingLocationSelection = true
            currentlySelectedPoint = location
            serchHelper?.selectPoint(point: location)
            isProcessingLocationSelection = false
        }
    }

    func mapView(_: BCMapView, didSwitchFloor floor: BCMapFloor) {
        print("🏢 MapView: Floor switched - \(floor.name ?? "Unknown")")
        floorSwitcher.selectFloor(floor)
    }

    func mapView(_: BCMapView, didLoadStep step: Any) {
        print("👣 MapView: Step loaded - \(step)")
    }

    func mapViewDidEndWalkthrough(_: BCMapView) {
        print("🏁 MapView: Walkthrough ended")
    }

    // MARK: - Data Retrieval

    func mapView(_: BCMapView, didReceiveCurrentFloor floor: BCMapFloor) {
        print("🏢 MapView: Current floor received - \(floor.name ?? "Unknown")")
    }

    func mapView(_ mapView: BCMapView, didReceiveRoute route: [BCRouteSegment]) {
        print("🗺️ MapView: Route received - \(route.count) segments")
        guard route.count > 0 else {
            return
        }

        // Store the route segments for later use
        routeSegments = route

        // Log segment details
        for (index, segment) in route.enumerated() {
            print(
                "🗺️ Segment \(index): orderIndex=\(segment.orderIndex), steps=\(segment.steps.count), distance=\(segment.distance)m"
            )
        }

        // Show the entire route on the map by default
        mapView.showRoute(segmentOrderIndex: route[0].orderIndex)

        // Notify search helper that route has been plotted
        if let searchHelper = serchHelper, let site = site {
            // Extract unique floor IDs from all route segments and steps
            var floorIds: Set<String> = []
            for segment in route {
                for step in segment.steps {
                    floorIds.insert(step.floorId)
                }
            }

            // Convert floor IDs to actual floor objects by filtering from site buildings
            let routeFloors = floorIds.compactMap { floorId in
                for building in site.buildings {
                    if let floors = building.floors {
                        if let floor = floors.first(where: { $0.id == floorId }) {
                            return floor
                        }
                    }
                }
                return nil
            }

            print("🗺️ Route: Route plotted with \(routeFloors.count) unique floors")
            searchHelper.didPlotRouteWith(points: routePoints, floorList: routeFloors)
        }
    }

    // MARK: - Search Results

    func mapView(_: BCMapView, didReceiveSearchResults results: [BCLocation]) {
        print("🔍 MapView: Search results received - \(results.count) results")
        // Update search list once with all results, not in a loop
        serchHelper?.updateSearchList(points: results)
    }

    func mapView(_: BCMapView, didReceiveSearchCategories categories: [BCCategory]) {
        print("🔍 MapView: Search categories received - \(categories.count) categories")
        for category in categories {
            print("   - \(category.name ?? "Unknown"): \(category.id ?? "No ID")")
        }
    }

    // MARK: - Error Handling

    func mapView(_: BCMapView, didReceiveError payload: Any) {
        print("❌ MapView: Received error - \(payload)")
    }
}

extension MapViewController: BEFloorSwitcherDelegate {
    func floorSwitcher(_: BEFloorSwitcher, didSelectFloor floor: BCMapFloor) {
        print("🏢 FloorSwitcher: User selected floor - \(floor.name ?? "Unknown")")

        // Switch to the selected floor on the map
        mapView.selectFloor(floor: floor)

        // Set viewport with floor's viewport options if available
        if let viewPort = floor.viewPort {
            print("🏢 FloorSwitcher: Setting viewport for floor - \(floor.name ?? "Unknown")")
            print("   - Zoom: \(viewPort.zoom ?? 18)")
            print("   - Pitch: \(viewPort.pitch ?? 0)")
            print("   - Bearing: \(viewPort.bearing ?? 0)")
            print("   - Center: \(viewPort.center ?? [])")

            mapView.setViewport(newOptions: viewPort)
        } else {
            print(
                "🏢 FloorSwitcher: No viewport options available for floor - \(floor.name ?? "Unknown")"
            )
        }
    }
}

extension MapViewController: BEMapAssistDelegate {
    func didRequestedForPreview(_: BESearchHelper) {
        //        mapView.preview()
    }

    func didRequestedForNavigation(_: BESearchHelper) {
        //        mapView.navigate()
    }

    func didReset(for _: BESearchHelper) {
        routePoints = []
        routeFloors = []
        routeSegments = []
        currentlySelectedPoint = nil
        isProcessingLocationSelection = false
        // Clear any displayed routes on the map
        mapView.clearAllRoute()
        print(
            "🔄 Reset: Cleared currently selected point, route data, route segments, processing flag, and map routes"
        )
        //        mapView.reset()
    }

    func searchHelper(_: BESearchHelper, didRequestedforRoute points: [BCLocation]) {
        guard points.count >= 2 else {
            print("❌ Route request: Need at least 2 points for a route")
            return
        }

        print(
            "🗺️ Route request: Planning route from \(points[0].name ?? "Unknown") to \(points[points.count - 1].name ?? "Unknown")"
        )

        // Create waypoints if there are more than 2 points
        let wayPoints: [BCLocation]? = points.count > 2 ? Array(points[1 ..< points.count - 1]) : nil

        // Create route options
        let routeOptions = BCRouteOptions()
        routeOptions.maxDistanceThreshold = 20
        routeOptions.getAccessiblePath = false

        // Store route points for later use
        routePoints = points

        // Request the route
        mapView.getRoute(
            start: points[0],
            goal: points[points.count - 1],
            wayPoints: wayPoints,
            routeOptions: routeOptions
        )
    }

    func searchHelper(_: BESearchHelper, didSelectPoint point: BCLocation) {
        // Prevent circular calls between map view and search helper
        guard !isProcessingLocationSelection else {
            print("🎯 SearchHelper: Skipping point selection - already processing")
            return
        }

        // Update the currently selected point to match the search helper's selection
        isProcessingLocationSelection = true
        currentlySelectedPoint = point
        print("🎯 SearchHelper: Point selected - \(point.name ?? "Unknown")")
        mapView.selectLocation(location: point)
        isProcessingLocationSelection = false
    }

    func searchHelper(_: BESearchHelper, didRequestedforResults text: String) {
        mapView.searchForLocation(searchString: text)
    }

    func searchHelper(_: BESearchHelper, didRequestedToShowRouteOn floor: BCMapFloor) {
        mapView.selectFloor(floor: floor)
    }

    // MARK: - Route Segment Management

    /**
     * Shows a specific route segment by its order index.
     *
     * - Parameter orderIndex: The order index of the segment to display
     */
    func showRouteSegment(orderIndex: Int) {
        guard !routeSegments.isEmpty else {
            print("❌ No route segments available to display")
            return
        }

        guard let segment = routeSegments.first(where: { $0.orderIndex == orderIndex }) else {
            print("❌ No segment found with order index \(orderIndex)")
            return
        }

        print("🗺️ Showing route segment \(orderIndex) with \(segment.steps.count) steps")
        mapView.showRoute(segmentOrderIndex: orderIndex)
    }

    /**
     * Gets all available route segment order indices.
     *
     * - Returns: Array of order indices for all route segments
     */
    func getAvailableSegmentIndices() -> [Int] {
        return routeSegments.map { $0.orderIndex }.sorted()
    }

    /**
     * Gets route segment information for debugging or UI display.
     *
     * - Returns: Array of dictionaries containing segment information
     */
    func getRouteSegmentInfo() -> [[String: Any]] {
        return routeSegments.map { segment in
            [
                "orderIndex": segment.orderIndex,
                "stepCount": segment.steps.count,
                "distance": segment.distance,
                "floors": Set(segment.steps.map { $0.floorId }).sorted(),
            ]
        }
    }
}

// MARK: - Array Extension for Unique Elements

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        return Array(Set(self))
    }
}

