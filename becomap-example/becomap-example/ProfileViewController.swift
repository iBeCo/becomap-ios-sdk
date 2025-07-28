//
//  ProfileViewController.swift
//  becomap-serve
//
//  Created by Mithin on 18/06/25.
//

import UIKit

class ProfileViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    private let helpButton = UIButton(type: .system)
    private let aboutButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProfileData()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Profile"

        // Setup ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Setup Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.backgroundColor = .systemGray5
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemGray
        profileImageView.translatesAutoresizingMaskIntoConstraints = false

        // Setup Labels
        nameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        emailLabel.font = UIFont.systemFont(ofSize: 16)
        emailLabel.textColor = .systemGray
        emailLabel.textAlignment = .center
        emailLabel.translatesAutoresizingMaskIntoConstraints = false

        // Setup Buttons
        setupButton(settingsButton, title: "Settings", icon: "gear")
        setupButton(helpButton, title: "Help & Support", icon: "questionmark.circle")
        setupButton(aboutButton, title: "About", icon: "info.circle")
        setupButton(logoutButton, title: "Logout", icon: "rectangle.portrait.and.arrow.right")
        logoutButton.setTitleColor(.systemRed, for: .normal)

        // Add subviews
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(settingsButton)
        contentView.addSubview(helpButton)
        contentView.addSubview(aboutButton)
        contentView.addSubview(logoutButton)

        // Setup Constraints
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Profile Image
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),

            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Email Label
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            emailLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Settings Button
            settingsButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            settingsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            settingsButton.heightAnchor.constraint(equalToConstant: 50),

            // Help Button
            helpButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 16),
            helpButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            helpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            helpButton.heightAnchor.constraint(equalToConstant: 50),

            // About Button
            aboutButton.topAnchor.constraint(equalTo: helpButton.bottomAnchor, constant: 16),
            aboutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            aboutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            aboutButton.heightAnchor.constraint(equalToConstant: 50),

            // Logout Button
            logoutButton.topAnchor.constraint(equalTo: aboutButton.bottomAnchor, constant: 40),
            logoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    private func setupButton(_ button: UIButton, title: String, icon: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: icon)
        configuration.imagePlacement = .leading
        configuration.imagePadding = 8
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        configuration.background.backgroundColor = .systemGray6
        configuration.cornerStyle = .medium

        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false

        // Add target
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }

    private func loadProfileData() {
        // TODO: Load actual profile data
        nameLabel.text = "John Doe"
        emailLabel.text = "john.doe@example.com"
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        switch sender {
        case settingsButton:
            showAlert(title: "Settings", message: "Settings functionality coming soon!")
        case helpButton:
            showAlert(title: "Help & Support", message: "Help and support functionality coming soon!")
        case aboutButton:
            showAlert(title: "About", message: "BeCoMap v2.0\n\nA powerful indoor mapping and navigation solution.")
        case logoutButton:
            showLogoutConfirmation()
        default:
            break
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Logout",
            message: "Are you sure you want to logout?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            // TODO: Implement logout functionality
            self.showAlert(title: "Logged Out", message: "You have been successfully logged out.")
        })
        present(alert, animated: true)
    }
}
