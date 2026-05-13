//
//  TransactionGroupDetailsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 19/09/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct TransactionGroupDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Namespace private var editingAnimation

    @State var transactionGroup: TransactionGroup

    @State private var isEditing = false
    @State private var showFullScreen = false
    @State private var draft: TransactionGroupDraft?
    @State private var validationErrors: [String] = []
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    private enum EditField { case title, notes, amount }
    @FocusState private var focusedField: EditField?

    private var isTrentePlusUser: Bool { true } // TODO: plug real entitlement
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    GroupBox {
                        VStack(spacing: 0) {
                            headerImageSection()
                            VStack(alignment: .leading, spacing: .small) {
                                titleField()
                                    .padding(.top, 12)
                                if transactionGroup.type == .expense {
                                    ViewThatFits(in: .horizontal) {
                                        HStack {
                                            categoryRow()
                                                .layoutPriority(1)
                                            amountRow()
                                                .layoutPriority(0)
                                        }
                                        VStack(alignment: .leading, spacing: .small) {
                                            categoryRow()
                                            amountRow()
                                        }
                                    }
                                }
                                if isTrentePlusUser {
                                    noteEditor()
                                }
                            }
                            .padding([.bottom, .horizontal])
                        }
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle(withPadding: false))

                    if transactionGroup.type == .income {
                        incomeRepartitionBox()
                            .disabled(!isEditing)
                    }
                    
                    GroupBox {
                        Text("Add delete transaction section")
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isEditing)
            .keyboardDismissButton(isVisible: focusedField != nil && isEditing) { focusedField = nil }
            .onChange(of: isEditing) { _, editing in if !editing { focusedField = nil } }
            .navigationTitle(isEditing ? "Editing" : transactionGroup.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent() }
            .alert("Cannot Save", isPresented: .constant(!validationErrors.isEmpty && isEditing == true)) {
                Button("OK") { validationErrors = [] }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
        }
    }

    // MARK: - Image
    
    @ViewBuilder
    private func headerImageSection() -> some View {
        ZStack(alignment: .bottomTrailing) {
            if isEditing {
                if let imageData = draft?.imageAttachmentData {
                    tappableImage(from: imageData)
                }
                if draft?.imageAttachmentData != nil {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Image", systemImage: "trash")
                    }
                    .padding([.bottom, .trailing])
                    .modifier(GlassOrBordered())
                    .tint(.red)
                    .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                draft?.imageAttachmentData = nil
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                } else {
                    PhotosPicker(selection: $photosPickerItem) {
                        Label("Add Image", systemImage: "photo.badge.plus")
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle())
                    .padding()
                }
            } else {
                if let imageData = transactionGroup.imageAttachmentData {
                    tappableImage(from: imageData)
                }
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                guard let item = newItem else {
                    draft?.imageAttachmentData = nil
                    return
                }
                do {
                    draft?.imageAttachmentData = try await item.loadTransferable(type: Data.self)
                } catch {
                    draft?.imageAttachmentData = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private func tappableImage(from imageData: Data) -> some View {
        if let uiImage = UIImage(data: imageData) {
            let image: Image = .init(uiImage: uiImage)
            
            Button {
                showFullScreen = true
            } label: {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                    )
            }
            .buttonStyle(.plain)
            .modify { view in
#if os(iOS)
                view.fullScreenCover(isPresented: $showFullScreen) {
                    ZoomableImageView(image: image)
                }
#else
                view
#endif
            }
        }
    }

    private struct GlassOrBordered: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Title
    
    @ViewBuilder
    private func titleField() -> some View {
        TextField(
            "Transaction title",
            text: Binding(
                get: { isEditing ? (draft?.title ?? transactionGroup.title) : transactionGroup.title },
                set: { draft?.title = $0 }
            ),
            axis: .vertical
        )
        .focused($focusedField, equals: .title)
        .disabled(!isEditing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title)
        .padding(isEditing ? 8 : 0)
        .background {
            if isEditing {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.2))
            }
        }
    }

    // MARK: - Category
    
    @ViewBuilder
    private func categoryRow() -> some View {
        if isEditing {
            categoryPicker()
                .matchedGeometryEffect(id: "category", in: editingAnimation, properties: .position)
        } else {
            categoryTag()
                .matchedGeometryEffect(id: "category", in: editingAnimation, properties: .position)
        }
    }
    
    @ViewBuilder
    private func categoryPicker() -> some View {
        Picker("Category",
               selection: Binding(
                get: { draft?.expenseCategory },
                set: { draft?.expenseCategory = $0 }
               )
        ) {
            ForEach(BudgetCategory.allCases) { category in
                Text(category.name)
                    .tag(category as BudgetCategory?)
            }
        }
        .frame(maxHeight: .infinity)
        .pickerStyle(.menu)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.2))
        }
    }
    
    @ViewBuilder
    private func categoryTag() -> some View {
        if let transactionCategory = transactionGroup.entries.first?.category {
            HStack {
                Circle()
                    .fill(transactionCategory.color)
                    .frame(width: 10, height: 10)
                Text(transactionCategory.name)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundStyle(transactionCategory.color.darken(0.6))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                Capsule()
                    .fill(transactionCategory.color.lighten(0.45))
                    .stroke(transactionCategory.color.darken(0.3).opacity(0.2))
            }
            .offset(x: -2)
        }
    }

    // MARK: - Amount
    
    @ViewBuilder
    private func amountRow() -> some View {
        if isEditing {
            amountTextField()
        } else if let displayAmount = transactionGroup.entries.first?.displayAmount {
                Text(displayAmount)
                .font(.subheadline)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    Capsule()
                        .fill(.gray.opacity(0.2))
                        .stroke(.primary.opacity(0.2))
                }
                .matchedGeometryEffect(id: "amount", in: editingAnimation, anchor: .leading)
        }
    }
    
    @ViewBuilder
    private func amountTextField() -> some View {
        CurrencyTextField(
            amountCents: Binding(
                get: {
                    let current = draft?.expenseAmountCents ?? transactionGroup.entries.first?.amountCents ?? 0
                    return -abs(current)
                },
                set: { newValue in
                    draft?.expenseAmountCents = -abs(newValue)
                }
            ),
            currency: transactionGroup.month.currency
        )
        .focused($focusedField, equals: .amount)
        .matchedGeometryEffect(id: "amount", in: editingAnimation, anchor: .leading)
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.2))
        }
    }

    // MARK: - Notes
    
    @ViewBuilder
    private func noteEditor() -> some View {
        TextField(
            "",
            text: Binding(
                get: {
                    if isEditing {
                        draft?.note ?? transactionGroup.note ?? ""
                    } else {
                        transactionGroup.note ?? ""
                    }
                },
                set: { draft?.note = $0 }
            ),
            prompt: Text("Add your notes here."),
            axis: .vertical
        )
        .focused($focusedField, equals: .notes)
        .lineLimit(5)
        .padding(isEditing ? 8 : 0)
        .background {
            if isEditing {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.2))
            }
        }
        .disabled(!isEditing)
    }

    // MARK: - Income Repartition
    
    @ViewBuilder
    private func incomeRepartitionBox() -> some View {
        GroupBox(label: Label("Income Repartition", systemImage: "chart.pie.fill")) {
            // Bind to draft when editing, otherwise show computed values
            let formatter = transactionGroup.month.currency.roundFormatter
            IncomeRepartitionComponent(
                repartition: Binding(
                    get: {
                        if isEditing {
                            draft?.incomeRepartition ?? [:]
                        } else {
                            // derive a read-only dictionary from current entries
                            Dictionary(grouping: transactionGroup.entries, by: \.category)
                                .mapValues { $0.map(\.amountCents).reduce(0, +) }
                        }
                    },
                    set: { newValue in
                        draft?.incomeRepartition = newValue
                    }
                ),
                amountToSplit: isEditing
                    ? (draft?.incomeAmountToSplitCents ?? transactionGroup.totalAmountCents)
                    : transactionGroup.totalAmountCents,
                formatter: formatter,
                isRepartitionComplete: Binding.constant(true) // let component compute if you expose it
            )
            .disabled(!isEditing)
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    withAnimation {
                        draft = nil
                        isEditing = false
                    }
                } label: { Label("Cancel", systemImage: "arrow.uturn.backward") }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    onTapDone()
                } label: { Label("Done", systemImage: "checkmark") }
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        draft = TransactionGroupDraft(from: transactionGroup)
                        isEditing = true
                    }
                } label: { Label("Edit", systemImage: "pencil") }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "chevron.down")
                }
            }
        }
    }

    // MARK: - Actions

    private func onTapDone() {
        guard var draft = draft else { return }
        // If income and amountToSplit isn't set explicitly, default to sum
        if transactionGroup.type == .income,
           draft.incomeAmountToSplitCents == 0 {
            draft.incomeAmountToSplitCents = draft.incomeRepartition.values.reduce(0, +)
            self.draft?.incomeAmountToSplitCents = draft.incomeAmountToSplitCents
        }
        let issues = draft.validate()
        if !issues.isEmpty {
            validationErrors = issues
            return
        }
        draft.apply(to: transactionGroup, context: modelContext)
        do {
            try modelContext.save()
            withAnimation {
                isEditing = false
            }
        } catch {
            validationErrors = ["Failed to save changes: \(error.localizedDescription)"]
        }
    }

    static func previewGroup() -> TransactionGroup {
        let month1 = Month(
            startDate: Date(),
            currency: Currencies.currency(for: "EUR")!,
            idealBudgetCents: 2000_00,
            idealRepartition: [
                .needs: 50,
                .wants: 30,
                .savingsAndDebts: 20
            ]
        )
        // Load placeholder image from assets and convert to data
        let imageData = UIImage(named: "placeholder")?.pngData()
        let shopping = TransactionGroup(
            title: String(localized: "Abercrombie & Fitch Lyon Part-Dieu"),
            type: .expense,
            month: month1,
            note: "This is a note about the transactionn and it is extremely interesting.",
            imageAttachmentData: imageData /*nil*/
        )
        shopping.entries = [
            TransactionEntry(amountCents: -119_99, category: .wants, group: shopping)
        ]
        return shopping
    }
}

#Preview {
    Text("Hi")
        .sheet(isPresented: .constant(true)) {
            TransactionGroupDetailsView(transactionGroup: TransactionGroupDetailsView.previewGroup())
        }
}

