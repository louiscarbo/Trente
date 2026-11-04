//
//  TrentePlusSection+ComparisonTable.swift
//  Trente
//

import SwiftUI

extension TrentePlusSection {
    struct ComparisonTable: View {
        let comparisons: [TrentePlusBenefit.Comparison]

        @State private var isShowingAll = false
        @ScaledMetric(relativeTo: .subheadline) private var columnWidth = 80.0
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        private let foldedCount = 5

        private var canFold: Bool {
            comparisons.count > foldedCount
        }

        private var visibleComparisons: [TrentePlusBenefit.Comparison] {
            isShowingAll ? comparisons : Array(comparisons.prefix(foldedCount))
        }

        var body: some View {
            VStack(spacing: 0) {
                if dynamicTypeSize.isAccessibilitySize {
                    stackedRows
                } else {
                    grid
                }
                if canFold {
                    Divider()
                        .padding(.leading)
                    foldButton
                }
            }
        }

        private var grid: some View {
            Grid(horizontalSpacing: 4, verticalSpacing: 0) {
                GridRow {
                    Color.clear
                        .gridCellUnsizedAxes([.horizontal, .vertical])
                    Text("Free")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: columnWidth)
                    Text("Trente+")
                        .frame(minWidth: columnWidth)
                        .padding(.trailing)
                }
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.top, 4)
                .padding(.bottom, 2)
                .accessibilityHidden(true)
                ForEach(visibleComparisons) { comparison in
                    if comparison.id != visibleComparisons.first?.id {
                        Divider()
                            .gridCellUnsizedAxes(.horizontal)
                    }
                    GridRow {
                        Text(comparison.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gridColumnAlignment(.leading)
                            .accessibilityLabel(Text(comparison.title))
                            .accessibilityValue(accessibilityValue(of: comparison))
                        offer(comparison.free)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: columnWidth)
                            .accessibilityHidden(true)
                        offer(comparison.plus)
                            .fontWeight(.semibold)
                            .frame(minWidth: columnWidth)
                            .padding(.trailing)
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 12)
                }
            }
            .padding(.leading)
        }

        private var stackedRows: some View {
            ForEach(visibleComparisons) { comparison in
                if comparison.id != visibleComparisons.first?.id {
                    Divider()
                        .padding(.leading)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(comparison.title)
                    Text("Free: \(offerDescription(comparison.free))")
                        .foregroundStyle(.secondary)
                    Text("Trente+: \(offerDescription(comparison.plus))")
                        .fontWeight(.semibold)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(comparison.title))
                .accessibilityValue(accessibilityValue(of: comparison))
            }
        }

        private func accessibilityValue(of comparison: TrentePlusBenefit.Comparison) -> Text {
            Text("Free: \(offerDescription(comparison.free)), Trente+: \(offerDescription(comparison.plus))")
        }

        @ViewBuilder
        private func offer(_ offer: TrentePlusBenefit.Offer) -> some View {
            switch offer {
            case .text(let value):
                Text(value)
                    .multilineTextAlignment(.center)
            case .included: Image(systemName: "checkmark")
            case .notIncluded: Text(verbatim: "—")
            }
        }

        private func offerDescription(_ offer: TrentePlusBenefit.Offer) -> Text {
            switch offer {
            case .text(let value): Text(value)
            case .included: Text("Included")
            case .notIncluded: Text("Not included")
            }
        }

        private var foldButton: some View {
            Button {
                withAnimation {
                    isShowingAll.toggle()
                }
            } label: {
                HStack {
                    Group {
                        if isShowingAll {
                            Text("Show less")
                        } else {
                            Text("Show all \(comparisons.count)")
                        }
                    }
                    .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isShowingAll ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    Form {
        Section {
            TrentePlusSection.ComparisonTable(comparisons: TrentePlusBenefit.comparisons)
                .listRowInsets(EdgeInsets())
        }
    }
    .formStyle(.grouped)
}
