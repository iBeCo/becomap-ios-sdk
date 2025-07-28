//
//  EventsViewController.swift
//  becomap-serve
//
//  Created by Mithin on 18/06/25.
//

import UIKit
import becomap_ios

class EventsViewController: UIViewController {
    private let tableView = UITableView()
    private var events: [BCHappenings] = []
    private var mapViewController: MapViewController?
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // Method to set the MapViewController reference
    func setMapViewController(_ mapViewController: MapViewController) {
        self.mapViewController = mapViewController
        // Set this view controller as the events delegate
        mapViewController.eventsDelegate = self
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Events"

        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        // Setup Empty State View
        emptyStateView.backgroundColor = .systemBackground
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        emptyStateLabel.text = "No events available"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .systemGray
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        emptyStateView.addSubview(emptyStateLabel)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
        ])

        // Initially show empty state
        updateEmptyState()
    }

    private func updateEventsList() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }

    private func updateEmptyState() {
        if events.isEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
        }
    }
}

// MARK: - UITableViewDataSource

extension EventsViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        let event = events[indexPath.row]

        cell.textLabel?.text = event.name
        cell.detailTextLabel?.text = event.description
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate

extension EventsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let event = events[indexPath.row]
        let alert = UIAlertController(
            title: event.name,
            message: event.description,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Events Delegate

extension EventsViewController {
    func didReceiveHappenings(_ happenings: [BCHappenings]) {
        print("🎉 EventsViewController: Happenings received - \(happenings.count) events")
        events = happenings
        updateEventsList()

        if happenings.isEmpty {
            print("📭 EventsViewController: No events available, showing empty state")
        }
    }
}
