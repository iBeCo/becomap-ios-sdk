//
//  BEFloorSwitcher.swift
//  becomap-ios
//
//  Created by Mithin on 10/07/25.
//

import UIKit
import becomap_ios

/// Protocol for handling floor switching events.
@objc protocol BEFloorSwitcherDelegate: AnyObject {
    /**
     * Called when user selects a floor from the switcher.
     *
     * - Parameter floor: The selected floor
     */
    func floorSwitcher(_ switcher: BEFloorSwitcher, didSelectFloor floor: BCMapFloor)
}

/// A UI component for switching between floors in a multi-floor building.
///
/// The FloorSwitcher displays the current floor by default and expands to show
/// all available floors when tapped. It provides both visual feedback and
/// programmatic control for floor selection.
@objc class BEFloorSwitcher: UIView {
    // MARK: - Properties

    /// Delegate to handle floor selection events
    @objc weak var delegate: BEFloorSwitcherDelegate?

    /// Array of available floors
    private var floors: [BCMapFloor] = []

    /// Currently selected floor
    private var currentFloor: BCMapFloor?

    /// Whether the floor list is expanded
    private var isExpanded: Bool = false

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var currentFloorButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.8
        button.titleLabel?.numberOfLines = 1
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 32)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleExpansion), for: .touchUpInside)
        return button
    }()

    private lazy var expandIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.down")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var floorsTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.layer.cornerRadius = 6
        tableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FloorCell.self, forCellReuseIdentifier: "FloorCell")
        return tableView
    }()

    // MARK: - Initialization

    /**
     * Initializes the FloorSwitcher with a frame.
     *
     * - Parameter frame: The frame for the FloorSwitcher
     */
    @objc override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /**
     * Initializes the FloorSwitcher with a decoder.
     *
     * - Parameter coder: The decoder to use for initialization
     */
    @objc required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /**
     * Convenience initializer for creating a FloorSwitcher.
     *
     * - Returns: A new FloorSwitcher instance
     */
    @objc convenience init() {
        self.init(frame: .zero)
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(currentFloorButton)
        currentFloorButton.addSubview(expandIcon)
        containerView.addSubview(floorsTableView)

        setupConstraints()
        updateCurrentFloorDisplay()

        // Add tap gesture to collapse when tapping outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap))
        tapGesture.cancelsTouchesInView = false
        addGestureRecognizer(tapGesture)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Current floor button
            currentFloorButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            currentFloorButton.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 4
            ),
            currentFloorButton.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -4
            ),
            currentFloorButton.heightAnchor.constraint(equalToConstant: 40),

            // Expand icon
            expandIcon.centerYAnchor.constraint(equalTo: currentFloorButton.centerYAnchor),
            expandIcon.trailingAnchor.constraint(
                equalTo: currentFloorButton.trailingAnchor, constant: -12
            ),
            expandIcon.widthAnchor.constraint(equalToConstant: 16),
            expandIcon.heightAnchor.constraint(equalToConstant: 16),

            // Floors table view
            floorsTableView.topAnchor.constraint(
                equalTo: currentFloorButton.bottomAnchor, constant: 2
            ),
            floorsTableView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 4
            ),
            floorsTableView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -4
            ),
            floorsTableView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor, constant: -4
            ),
            floorsTableView.heightAnchor.constraint(equalToConstant: 0), // Start collapsed
        ])
    }

    // MARK: - Public Methods

    /**
     * Sets the available floors for the switcher.
     *
     * - Parameter floors: Array of available floors
     */
    @objc func setFloors(_ floors: [BCMapFloor]) {
        self.floors = floors.sorted { floor1, floor2 in
            // Sort by elevation (higher floors first) or by name
            if let elev1 = floor1.elevation, let elev2 = floor2.elevation {
                return elev1 > elev2
            }
            return (floor1.name ?? "") > (floor2.name ?? "")
        }

        // Set first floor as current if no current floor is set
        if currentFloor == nil && !floors.isEmpty {
            currentFloor = floors.first
        }

        floorsTableView.reloadData()
        updateCurrentFloorDisplay()
    }

    /**
     * Programmatically selects a floor.
     *
     * - Parameter floor: The floor to select
     */
    @objc func selectFloor(_ floor: BCMapFloor) {
        guard floors.contains(where: { $0.id == floor.id }) else { return }

        currentFloor = floor
        updateCurrentFloorDisplay()

        // Reload table view to update selection indicators
        floorsTableView.reloadData()

        // Collapse if expanded
        if isExpanded {
            toggleExpansion()
        }

        // Notify delegate
        delegate?.floorSwitcher(self, didSelectFloor: floor)
    }

    /**
     * Gets the currently selected floor.
     *
     * - Returns: The currently selected floor, or nil if none is selected
     */
    @objc func getCurrentFloor() -> BCMapFloor? {
        return currentFloor
    }

    // MARK: - Private Methods

    @objc private func toggleExpansion() {
        isExpanded.toggle()

        UIView.animate(
            withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            if self.isExpanded {
                // Expand
                for constraint in self.floorsTableView.constraints {
                    if constraint.firstAttribute == .height
                        && constraint.firstItem === self.floorsTableView
                    {
                        constraint.isActive = false
                    }
                }
                self.floorsTableView.heightAnchor.constraint(
                    equalToConstant: min(200, CGFloat(self.floors.count * 44))
                ).isActive = true
                self.expandIcon.transform = CGAffineTransform(rotationAngle: .pi)
            } else {
                // Collapse
                for constraint in self.floorsTableView.constraints {
                    if constraint.firstAttribute == .height
                        && constraint.firstItem === self.floorsTableView
                    {
                        constraint.isActive = false
                    }
                }
                self.floorsTableView.heightAnchor.constraint(equalToConstant: 0).isActive = true
                self.expandIcon.transform = .identity
            }
            self.layoutIfNeeded()
        }
    }

    private func updateCurrentFloorDisplay() {
        if let currentFloor = currentFloor {
            let displayName = currentFloor.name ?? currentFloor.shortName ?? "Unknown"
            currentFloorButton.setTitle("\(displayName)", for: .normal)
        } else {
            currentFloorButton.setTitle("Select Floor", for: .normal)
        }
    }

    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        if !containerView.frame.contains(location) && isExpanded {
            toggleExpansion()
        }
    }
}

// MARK: - UITableViewDataSource

extension BEFloorSwitcher: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return floors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =
            tableView.dequeueReusableCell(withIdentifier: "FloorCell", for: indexPath) as! FloorCell
        let floor = floors[indexPath.row]
        cell.configure(with: floor, isSelected: floor.id == currentFloor?.id)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BEFloorSwitcher: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedFloor = floors[indexPath.row]
        selectFloor(selectedFloor)
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - FloorCell

/// Custom table view cell for displaying floor information.
private class FloorCell: UITableViewCell {
    private let floorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let checkmarkIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = UIColor.systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(floorLabel)
        contentView.addSubview(checkmarkIcon)

        NSLayoutConstraint.activate([
            floorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            floorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            floorLabel.trailingAnchor.constraint(
                equalTo: checkmarkIcon.leadingAnchor, constant: -8
            ),

            checkmarkIcon.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor, constant: -12
            ),
            checkmarkIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 16),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    func configure(with floor: BCMapFloor, isSelected: Bool) {
        let displayName = floor.name ?? floor.shortName ?? "Unknown"
        floorLabel.text = displayName

        if isSelected {
            floorLabel.textColor = .systemBlue
            floorLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            checkmarkIcon.isHidden = false
        } else {
            floorLabel.textColor = .darkGray
            floorLabel.font = UIFont.systemFont(ofSize: 14)
            checkmarkIcon.isHidden = true
        }
    }
}
