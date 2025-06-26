//
//  NewTransactionView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/04/2025.
//

import SwiftUI
import PhotosUI

struct NewTransactionView: View {
    // View Arguments
    var currency: Currency
    
    // Transaction Data
    @State private var selectedCategory: BudgetCategory?
    @State private var amountCents: Int = 0
    @State private var type: TransactionType = .income
    @State private var title: String = ""
    @State private var isRecurrent: Bool = true
    @State private var image: Image?
    @State private var notes: String = ""
    @State private var recurrenceFrequency: RecurrenceFrequency = .monthly
    @State private var recurrenceStartDate: Date = Date()
    @State private var recurrenceEndDate: Date?
    
    // Buttons Logic
    private var showPreviousButton: Bool {
        step != .amountCategory
    }
    private var showNextButton: Bool {
        step != .repartitionRecurrence
    }
    @State private var nextButtonDisabled: Bool = true
    
    // View State
    @State var step: NewTransactionStep = .amountCategory
    @State private var showKeyboardDismissButton: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // TODO: Create custom view for macOS
                TabView(selection: $step) {
                    AmountCategoryView(
                        selectedCategory: $selectedCategory,
                        amountCents: $amountCents,
                        transactionType: $type,
                        nextButtonDisabled: $nextButtonDisabled,
                        isRecurrent: $isRecurrent,
                        
                        currencyCode: currency.isoCode
                    )
                    .newTransactionPage(tag: .amountCategory)
                    
                    TitleView(
                        title: $title,
                        
                        nextButtonDisabled: $nextButtonDisabled,
                        step: $step,
                        showKeyboardDismissButton: $showKeyboardDismissButton
                    )
                    .newTransactionPage(tag: .title)
                    
                    NotesImageView(
                        image: $image,
                        notes: $notes,
                        
                        showKeyboardDismissButton: $showKeyboardDismissButton
                    )
                    .newTransactionPage(tag: .notesImage)
                    
                    RepartitionRecurrenceView(
                        showRecurrence: isRecurrent,
                        showIncomeRepartition: type == .income
                    )
                    .newTransactionPage(tag: .repartitionRecurrence)
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #elseif os(macOS)
                .tabViewStyle(.automatic)
                #endif
                .navigationTitle("New Transaction")
                .toolbarTitleDisplayMode(.inline)
                
                navigationButtons
            }
        }
    }
    
    var navigationButtons: some View {
        VStack {
            HStack(spacing: 20) {
                if showPreviousButton {
                    Button("Previous") {
                        withAnimation {
                            if let previousStep = step.previous() {
                                step = previousStep
                            } else {
                                print("Already at the first step")
                            }
                        }
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
                }
                
                Button("Next") {
                    withAnimation {
                        if let nextStep = step.next(isRecurrent: isRecurrent, isIncome: type == .income) {
                            step = nextStep
                        } else {
                            print("Transaction creation completed")
                        }
                    }
                }
                .disabled(nextButtonDisabled)
                .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
            }
            
            #if os(iOS)
            if showKeyboardDismissButton {
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                    showKeyboardDismissButton = false
                } label: {
                    Label("Done", systemImage: "keyboard.chevron.compact.down")
                }
                .buttonStyle(TrenteSecondaryButtonStyle(narrow: true))
            }
            #endif
        }
        .padding()
        .background {
            UnevenRoundedRectangle(
                cornerRadii:
                    RectangleCornerRadii(topLeading: 26, bottomLeading: 0, bottomTrailing: 0, topTrailing: 26)
            )
            .fill(.regularMaterial)
            .stroke(.secondary.opacity(0.4), lineWidth: 3)
            .ignoresSafeArea()
        }
    }
    
    struct NewTransactionViewModifier: ViewModifier {
        let tag: NewTransactionStep
        
        func body(content: Content) -> some View {
            ZStack {
                Rectangle().fill(.clear)
                content
            }
            .tag(tag)
            .contentShape(Rectangle())
            .gesture(DragGesture())
        }
    }
}

enum NewTransactionStep {
    case amountCategory
    case title
    case notesImage
    case repartitionRecurrence
    
    func next(isRecurrent: Bool, isIncome: Bool) -> NewTransactionStep? {
        switch self {
        case .amountCategory:
            return .title
        case .title:
            return .notesImage
        case .notesImage:
            if isRecurrent || isIncome {
                return .repartitionRecurrence
            } else {
                return nil
            }
        case .repartitionRecurrence:
            return nil
        }
    }
    
    func previous() -> NewTransactionStep? {
        switch self {
        case .amountCategory:
            return nil
        case .title:
            return .amountCategory
        case .notesImage:
            return .title
        case .repartitionRecurrence:
            return .notesImage
        }
    }
}

extension View {
    func newTransactionPage(tag: NewTransactionStep) -> some View {
        modifier(NewTransactionView.NewTransactionViewModifier(tag: tag))
    }
}

// MARK: AmountCategoryView
private struct AmountCategoryView: View {
    // Bindings
    @Binding var selectedCategory: BudgetCategory?
    @Binding var amountCents: Int
    @Binding var transactionType: TransactionType
    @Binding var nextButtonDisabled: Bool
    @Binding var isRecurrent: Bool
    
    // View arguments
    var currencyCode: String
    
    // View State
    @State private var amountText = ""
    @FocusState private var amountFieldIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            if transactionType == .expense {
                Picker("Select Category", selection: $selectedCategory) {
                    ForEach(BudgetCategory.allCases, id: \.self) { category in
                        Text(category.shortName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                Spacer()
                    .frame(height: 25)
            }
            
            Label(transactionType == .income
                  ? "You will select categories for this income in the next steps."
                  : selectedCategory?.shortExamples ?? "Select a category for this transaction.", systemImage: "info.circle")
            .font(.headline)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 0) {
                Picker("Income/Expense", selection: $transactionType) {
                    Image(systemName: "minus").tag(TransactionType.expense)
                    Image(systemName: "plus").tag(TransactionType.income)
                }
                .pickerStyle(.inline)
                .frame(width: 60)
                
                TextField(
                    "",
                    text: $amountText,
                    prompt: Text("\(0.formatted(.currency(code: currencyCode)))")
                )
                .focused($amountFieldIsFocused)
                #if os(iOS)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.system(size: 80, weight: .bold))
                .multilineTextAlignment(.center)
                #endif
            }
            
            Spacer()
            
            Toggle(isOn: $isRecurrent) {
                Text("Recurring transaction")
                    .font(.headline)
            }
            .toggleStyle(TrenteToggleStyle())
        }
        .padding([.horizontal, .bottom])
        .onChange(of: amountText) { oldValue, newValue in
            processAmountTextChange(newValue: newValue, oldValue: oldValue)
            updateNextButtonState()
        }
        .onChange(of: transactionType) { _, newValue in
            applySign()
            updateNextButtonState()
            if newValue == .income {
                selectedCategory = nil
            }
        }
        .onChange(of: selectedCategory) {
            updateNextButtonState()
        }
        .onAppear {
            updateNextButtonState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                amountFieldIsFocused = true
            }
        }
    }
    
    // Text validation and amount in cents calculation
    private func processAmountTextChange(newValue: String, oldValue: String) {
        let decimalSep = Locale.current.decimalSeparator ?? "."
        
        // 1) Strip any leading sign for validation
        let unsigned = newValue.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
        
        // 1a) Prevent more than one decimal separator
        let sepChar = Character(decimalSep)
        let sepCount = unsigned.filter { $0 == sepChar }.count
        if sepCount > 1 {
            amountText = oldValue
            return
        }
        
        // 1b) Enforce max two decimal places
        if let idx = unsigned.firstIndex(of: sepChar) {
            let frac = unsigned[unsigned.index(after: idx)...]
            if frac.count > 2 {
                amountText = oldValue
                return
            }
        }
        
        // 1c) If now empty, clear everything
        guard !unsigned.isEmpty else {
            amountText = ""
            amountCents = 0
            return
        }
        
        // 1d) Parse number respecting locale
        let fmt = NumberFormatter()
        fmt.locale = Locale.current
        fmt.numberStyle = .decimal
        let dbl = fmt.number(from: unsigned)?.doubleValue ?? 0
        
        // 1e) Compute absolute cents
        let absCents = Int((dbl * 100).rounded())
        
        // 1f) Update the text to the unsigned digits
        amountText = unsigned
        
        // 1g) Store signed cents & re-attach sign
        amountCents = transactionType == .income ? absCents : -absCents
        applySign()
    }
    
    private func applySign() {
        // 2a) Normalize amountCents to match isIncome
        if transactionType == .income {
            amountCents = abs(amountCents)
        } else {
            amountCents = -abs(amountCents)
        }
        
        // 2b) Rebuild amountText with proper prefix
        let unsigned = amountText.trimmingCharacters(in: CharacterSet(charactersIn: "+-"))
        let prefix = transactionType == .income ? "" : "-"
        amountText = prefix + unsigned
    }
    
    private func updateNextButtonState() {
        if transactionType == .income {
            if amountCents != 0 {
                nextButtonDisabled = false
            } else {
                nextButtonDisabled = true
            }
        } else {
            if amountCents != 0 && selectedCategory != nil {
                nextButtonDisabled = false
            } else {
                nextButtonDisabled = true
            }
        }
    }
}

// MARK: TitleView
private struct TitleView: View {
    // Transaction Data
    @Binding var title: String
    
    // View Bindings
    @Binding var nextButtonDisabled: Bool
    @Binding var step: NewTransactionStep
    @Binding var showKeyboardDismissButton: Bool
    
    // View Logic
    @FocusState private var titleFieldIsFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Label("Give a title to your transaction", systemImage: "info.circle")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                TextField(
                    "",
                    text: $title,
                    prompt: Text("Title"),
                    axis: .vertical
                )
                .lineLimit(3)
                .focused($titleFieldIsFocused)
                .textFieldStyle(.plain)
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: title) {
            updateNextButtonState()
        }
        .onChange(of: titleFieldIsFocused) { _, newValue in
            if newValue == true {
                showKeyboardDismissButton = true
            } else {
                showKeyboardDismissButton = false
            }
        }
        .onAppear {
            updateNextButtonState()
            titleFieldIsFocused = true
        }
        .onChange(of: step) { _, newStep in
            if newStep != .title {
                titleFieldIsFocused = false
            }
        }
    }
    
    private func updateNextButtonState() {
        if title.isEmpty {
            nextButtonDisabled = true
        } else {
            nextButtonDisabled = false
        }
    }
}

// MARK: NotesImageView
private struct NotesImageView: View {
    // Transaction attributes
    @Binding var image: Image?
    @Binding var notes: String
    
    // Bindings
    @Binding var showKeyboardDismissButton: Bool
    
    // View arguments
    @State private var userSubscriptionIsActive: Bool = true
    
    // View logic
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showImageSubscriptionSheet: Bool = false
    @State private var showFullScreen = false
    @FocusState private var notesFocused: Bool
    
    var body: some View {
        ZStack {
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    if photosPickerItem == nil {
                        PhotosPicker(selection: $photosPickerItem) {
                            Label("Add Image", systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(TrenteSecondaryButtonStyle())
                    } else {
                        if let selectedImage = image {
                            selectedImage
                                .resizable()
                                .scaledToFit()
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 26)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26)
                                        .stroke(Color.white, lineWidth: 10)
                                )
                                .frame(height: 200)
                                .shadow(radius: 26, y: 10)
                                .padding(.bottom, 30)
                                .overlay(alignment: .bottom) {
                                    PhotosPicker(selection: $photosPickerItem) {
                                        Label("Change Image", systemImage: "photo.badge.plus")
                                            .font(.headline)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(TrenteSecondaryButtonStyle())
                                    .fixedSize()
                                }
                                .onTapGesture {
                                    showFullScreen = true
                                }
                                .modify { view in
                                    #if os(iOS)
                                        view.fullScreenCover(isPresented: $showFullScreen) {
                                            ZoomableImageView(image: selectedImage)
                                        }
                                    #else
                                        view
                                    #endif
                                }
                                
                        } else {
                            // fallback while loading
                            ProgressView()
                                .frame(height: 400)
                        }
                    }
                    
                    GroupBox(label: Label("Transaction Notes", systemImage: "note.text")) {
                        TextField(
                            "",
                            text: $notes,
                            prompt: Text("Add your notes here."),
                            axis: .vertical
                        )
                        .focused($notesFocused)
                        .lineLimit(5, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)
                        .textFieldStyle(.plain)
                        .onChange(of: notesFocused) { _, newValue in
                            if newValue == true {
                                showKeyboardDismissButton = true
                            } else {
                                showKeyboardDismissButton = false
                            }
                        }
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
                .padding()
                .padding(.top, 30)
            }
            .subscriptionAccessible(subscribed: userSubscriptionIsActive)
            .onChange(of: photosPickerItem) { _, newItem in
                guard let item = newItem else {
                    image = nil
                    return
                }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let selectedImage = createImage(data) {
                        image = selectedImage
                    }
                }
            }
            
            // Subscription Invite
            if !userSubscriptionIsActive {
                GroupBox(label: Label("Add Notes and Images", systemImage: "sparkle")) {
                    Text("With Trente+, you can add images and notes to your transactions. Try it now!")
                        .padding(.bottom)
                    
                    Button {
                        showImageSubscriptionSheet = true
                    } label: {
                        Text("Discover Trente+")
                            .font(.title3)
                    }
                    .buttonStyle(TrentePrimaryButtonStyle())
                    .sheet(isPresented: $showImageSubscriptionSheet) {
                        SubscriptionView()
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())
                .padding()
            }
        }
    }
}

// MARK: RepartitionRecurrenceView
private struct RepartitionRecurrenceView: View {
    @State var showRecurrence: Bool
    @State var showIncomeRepartition: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                if showIncomeRepartition {
                    GroupBox(label: Text("Income Repartition")) {
                        Text("Hello there")
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
                if showRecurrence {
                    GroupBox(label: Text("Recurrence")) {
                        Text("Hello here")
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
            }
            .padding()
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            NewTransactionView(currency: Currency(isoCode: "EUR", symbol: "eurosign", localizedName: "Euro"), step: .repartitionRecurrence)
        }
}
