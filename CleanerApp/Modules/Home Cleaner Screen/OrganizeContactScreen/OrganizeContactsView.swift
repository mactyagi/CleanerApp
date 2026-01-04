//
//  OrganizeContactsView.swift
//  CleanerApp
//
//  Dashboard Style SwiftUI View for Organize Contacts
//

import SwiftUI
import Contacts

struct OrganizeContactsView: View {
    @ObservedObject var viewModel: OrganizeContactViewModel

    // Navigation callbacks
    var onDuplicatesTapped: (() -> Void)?
    var onIncompleteTapped: (() -> Void)?
    var onBackupTapped: (() -> Void)?
    var onAllContactsTapped: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section with Total Contacts
                OCHeroSection(totalContacts: viewModel.allContacts.count)

                // Stats Row
                OCStatsRow(
                    duplicates: viewModel.duplicateCount,
                    incomplete: viewModel.incompleteContacts.count
                )

                // Action Cards
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        OCActionCard(
                            icon: "person.2.fill",
                            title: "Duplicates",
                            count: viewModel.duplicateCount,
                            color: .blue,
                            isPrimary: viewModel.duplicateCount > 0
                        ) {
                            onDuplicatesTapped?()
                        }

                        OCActionCard(
                            icon: "person.crop.circle.badge.questionmark",
                            title: "Incomplete",
                            count: viewModel.incompleteContacts.count,
                            color: .orange,
                            isPrimary: viewModel.incompleteContacts.count > 0
                        ) {
                            onIncompleteTapped?()
                        }
                    }

                    HStack(spacing: 16) {
                        OCActionCard(
                            icon: "square.and.arrow.down.fill",
                            title: "Backup",
                            count: nil,
                            color: .teal,
                            isPrimary: true
                        ) {
                            onBackupTapped?()
                        }

                        OCActionCard(
                            icon: "rectangle.stack.person.crop.fill",
                            title: "All Contacts",
                            count: viewModel.allContacts.count,
                            color: .indigo,
                            isPrimary: true
                        ) {
                            onAllContactsTapped?()
                        }
                    }
                }
                .padding(.horizontal)

                // Tips Section
                OCTipsSection()

                Spacer(minLength: 100)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Contacts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hero Section
struct OCHeroSection: View {
    let totalContacts: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "667EEA").opacity(0.4), radius: 16, x: 0, y: 8)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text("\(totalContacts)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Text("Total Contacts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 24)
    }
}

// MARK: - Stats Row
struct OCStatsRow: View {
    let duplicates: Int
    let incomplete: Int

    private var totalIssues: Int { duplicates + incomplete }

    var body: some View {
        HStack(spacing: 0) {
            OCStatItem(
                value: "\(duplicates)",
                label: "Duplicates",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            OCStatItem(
                value: "\(incomplete)",
                label: "Incomplete",
                color: .orange
            )

            Divider()
                .frame(height: 40)

            OCStatItem(
                value: totalIssues == 0 ? "✓" : "\(totalIssues)",
                label: "Issues",
                color: totalIssues == 0 ? .green : .red
            )
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Stat Item
struct OCStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Card
struct OCActionCard: View {
    let icon: String
    let title: String
    let count: Int?
    let color: Color
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isPrimary ? color : color.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(isPrimary ? .white : color)
                    }

                    Spacer()

                    if isPrimary {
                        Text("Action needed")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.8))
                            .cornerRadius(8)
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    if let count = count {
                        Text("\(count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(isPrimary ? .white : .primary)
                    }

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isPrimary ? .white.opacity(0.9) : .secondary)
                }
            }
            .padding()
            .frame(height: 130)
            .background(
                isPrimary ?
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: isPrimary ? color.opacity(0.3) : Color.black.opacity(0.05),
                radius: isPrimary ? 12 : 8,
                x: 0,
                y: isPrimary ? 6 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tips Section
struct OCTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    OCTipCard(
                        icon: "lightbulb.fill",
                        title: "Merge Duplicates",
                        description: "Keep your contacts clean by merging duplicates",
                        color: .yellow
                    )

                    OCTipCard(
                        icon: "arrow.clockwise",
                        title: "Regular Backup",
                        description: "Export contacts regularly to prevent data loss",
                        color: .blue
                    )

                    OCTipCard(
                        icon: "checkmark.circle.fill",
                        title: "Complete Info",
                        description: "Add missing details to incomplete contacts",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Tip Card
struct OCTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        OrganizeContactsView(viewModel: OrganizeContactViewModel(contactStore: CNContactStore()))
    }
}
