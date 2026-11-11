//
//  StoreCaptureLanguage.swift
//  Trente
//

#if DEBUG
import Foundation

struct StoreCaptureLanguage {
    let currencyCode: String
    var amountScale = 1
    var titles: [String: String] = [:]

    func localized(_ title: String) -> String {
        titles[title] ?? title
    }

    static let current: StoreCaptureLanguage = {
        let language = Locale.current.language
        let code = language.languageCode?.identifier ?? "en"
        let key = code == "pt" ? "pt-\(language.region?.identifier ?? "BR")" : code
        return all[key] ?? StoreCaptureLanguage(currencyCode: "USD")
    }()

    static let all: [String: StoreCaptureLanguage] = [
        "fr": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Salaire", "Direct deposit": "Virement", "Rent": "Loyer", "Roth IRA": "PEA",
            "Verizon": "Orange", "Student Loan": "Prêt étudiant", "GEICO": "MAIF",
            "Trader Joe's": "Monoprix", "Chipotle": "Big Fernand", "Shell": "TotalEnergies",
            "Olive Garden": "Hippopotamus", "CVS Pharmacy": "Pharmacie",
            "Sweetgreen": "Cojean", "Whole Foods": "Naturalia", "AMC Theatres": "Pathé",
            "Con Edison": "EDF", "Ticketmaster": "Fnac Spectacles", "Target": "Carrefour",
            "Ally Savings": "Livret A", "Delta Air Lines": "Air France", "Jiffy Lube": "Norauto"
        ]),
        "es": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Nómina", "Direct deposit": "Transferencia", "Rent": "Alquiler", "Roth IRA": "Plan de pensiones",
            "Verizon": "Movistar", "Student Loan": "Préstamo", "GEICO": "Mapfre",
            "Trader Joe's": "Mercadona", "Chipotle": "Goiko", "Shell": "Repsol",
            "Olive Garden": "VIPS", "CVS Pharmacy": "Farmacia",
            "Sweetgreen": "Honest Greens", "Whole Foods": "Carrefour", "AMC Theatres": "Cinesa",
            "Con Edison": "Iberdrola", "Uber": "Cabify", "Target": "El Corte Inglés",
            "Ally Savings": "Cuenta de ahorro", "Delta Air Lines": "Iberia", "Jiffy Lube": "Midas"
        ]),
        "it": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Stipendio", "Direct deposit": "Bonifico", "Rent": "Affitto", "Roth IRA": "Fondo pensione",
            "Verizon": "TIM", "Student Loan": "Prestito", "GEICO": "UnipolSai",
            "Trader Joe's": "Esselunga", "Chipotle": "Old Wild West", "Shell": "Eni",
            "Olive Garden": "Rossopomodoro", "CVS Pharmacy": "Farmacia",
            "Sweetgreen": "Poke House", "Whole Foods": "NaturaSì", "AMC Theatres": "UCI Cinemas",
            "Con Edison": "Enel", "Ticketmaster": "TicketOne", "Target": "Coop",
            "Ally Savings": "Conto deposito", "Delta Air Lines": "ITA Airways", "Jiffy Lube": "Midas"
        ]),
        "de": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Gehalt", "Direct deposit": "Überweisung", "Rent": "Miete", "Roth IRA": "ETF-Sparplan",
            "Verizon": "Telekom", "Student Loan": "Studienkredit", "GEICO": "HUK-Coburg",
            "Trader Joe's": "REWE", "Chipotle": "Vapiano", "Shell": "Aral",
            "Olive Garden": "Block House", "CVS Pharmacy": "dm",
            "Sweetgreen": "dean&david", "Whole Foods": "Alnatura", "AMC Theatres": "CinemaxX",
            "Con Edison": "Vattenfall", "Ticketmaster": "Eventim", "Target": "Edeka",
            "Ally Savings": "Tagesgeld", "Delta Air Lines": "Lufthansa", "Jiffy Lube": "ATU"
        ]),
        "ko": StoreCaptureLanguage(currencyCode: "KRW", amountScale: 1000, titles: [
            "Paycheck": "월급", "Direct deposit": "급여 이체", "Rent": "월세", "Roth IRA": "연금저축",
            "Verizon": "SKT", "Student Loan": "학자금 대출", "GEICO": "삼성화재",
            "Trader Joe's": "이마트", "Chipotle": "맘스터치", "Shell": "GS칼텍스", "Amazon": "쿠팡",
            "Olive Garden": "아웃백", "CVS Pharmacy": "올리브영",
            "Sweetgreen": "샐러디", "Whole Foods": "홈플러스", "AMC Theatres": "CGV",
            "Con Edison": "한국전력", "Uber": "카카오T", "Ticketmaster": "인터파크 티켓", "Target": "다이소",
            "Ally Savings": "적금", "Delta Air Lines": "대한항공", "Jiffy Lube": "스피드메이트"
        ]),
        "pt-BR": StoreCaptureLanguage(currencyCode: "BRL", titles: [
            "Paycheck": "Salário", "Direct deposit": "Depósito em conta", "Rent": "Aluguel", "Roth IRA": "Previdência",
            "Verizon": "Vivo", "Student Loan": "FIES", "GEICO": "Porto Seguro",
            "Trader Joe's": "Pão de Açúcar", "Chipotle": "Madero", "Shell": "Ipiranga",
            "Olive Garden": "Outback", "CVS Pharmacy": "Drogasil",
            "Sweetgreen": "Spoleto", "Whole Foods": "Carrefour", "AMC Theatres": "Cinemark",
            "Con Edison": "Enel", "Ticketmaster": "Sympla", "Target": "Americanas",
            "Ally Savings": "Reserva de emergência", "Delta Air Lines": "LATAM", "Jiffy Lube": "Auto Center"
        ]),
        "pt-PT": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Salário", "Direct deposit": "Transferência", "Rent": "Renda", "Roth IRA": "PPR",
            "Verizon": "MEO", "Student Loan": "Empréstimo", "GEICO": "Fidelidade",
            "Trader Joe's": "Continente", "Chipotle": "H3", "Shell": "Galp",
            "Olive Garden": "Portugália", "CVS Pharmacy": "Farmácia",
            "Sweetgreen": "Vitaminas", "Whole Foods": "Pingo Doce", "AMC Theatres": "Cinemas NOS",
            "Con Edison": "EDP", "Uber": "Bolt", "Ticketmaster": "BOL", "Target": "Lidl",
            "Ally Savings": "Certificados de Aforro", "Delta Air Lines": "TAP", "Jiffy Lube": "Midas"
        ]),
        "da": StoreCaptureLanguage(currencyCode: "DKK", amountScale: 10, titles: [
            "Paycheck": "Løn", "Direct deposit": "Overførsel", "Rent": "Husleje", "Roth IRA": "Aldersopsparing",
            "Verizon": "Telenor", "Student Loan": "SU-lån", "GEICO": "Tryg", "Trader Joe's": "Netto",
            "Chipotle": "Sunset Boulevard", "Shell": "Circle K", "Olive Garden": "Jensens Bøfhus",
            "CVS Pharmacy": "Matas", "Sweetgreen": "Joe & The Juice", "Whole Foods": "Meny",
            "AMC Theatres": "Nordisk Film", "Con Edison": "Norlys", "Uber": "Dantaxi", "Target": "Bilka",
            "Ally Savings": "Opsparingskonto", "Delta Air Lines": "SAS", "Jiffy Lube": "AutoMester",
            "Amazon": "Elgiganten"
        ]),
        "el": StoreCaptureLanguage(currencyCode: "EUR", titles: [
            "Paycheck": "Μισθός", "Direct deposit": "Μισθοδοσία", "Rent": "Ενοίκιο",
            "Roth IRA": "Συνταξιοδοτικό", "Verizon": "Cosmote", "Student Loan": "Δάνειο",
            "GEICO": "Interamerican", "Trader Joe's": "Σκλαβενίτης", "Chipotle": "Goody's", "Shell": "EKO",
            "Olive Garden": "Ταβέρνα", "CVS Pharmacy": "Φαρμακείο", "Sweetgreen": "Everest",
            "Whole Foods": "ΑΒ Βασιλόπουλος", "AMC Theatres": "Village Cinemas", "Con Edison": "ΔΕΗ",
            "Ticketmaster": "Συναυλία", "Target": "Jumbo", "Ally Savings": "Ταμιευτήριο",
            "Delta Air Lines": "Aegean", "Jiffy Lube": "Συνεργείο", "Amazon": "Skroutz"
        ]),
        "ja": StoreCaptureLanguage(currencyCode: "JPY", amountScale: 100, titles: [
            "Paycheck": "給料", "Direct deposit": "給与振込", "Rent": "家賃", "Roth IRA": "iDeCo", "Verizon": "ドコモ",
            "Student Loan": "奨学金", "GEICO": "ソニー損保", "Trader Joe's": "イオン", "Chipotle": "スシロー", "Shell": "ENEOS",
            "Olive Garden": "鳥貴族", "CVS Pharmacy": "マツモトキヨシ", "Sweetgreen": "モスバーガー", "Whole Foods": "成城石井",
            "AMC Theatres": "TOHOシネマズ", "Con Edison": "東京電力", "Ticketmaster": "チケットぴあ", "Target": "ドン・キホーテ",
            "Ally Savings": "積立貯金", "Delta Air Lines": "JAL", "Jiffy Lube": "オートバックス"
        ]),
        "sv": StoreCaptureLanguage(currencyCode: "SEK", amountScale: 10, titles: [
            "Paycheck": "Lön", "Direct deposit": "Insättning", "Rent": "Hyra", "Roth IRA": "ISK",
            "Verizon": "Telia", "Student Loan": "CSN-lån", "GEICO": "Folksam", "Trader Joe's": "ICA",
            "Chipotle": "Max", "Shell": "Circle K", "Olive Garden": "O'Learys", "CVS Pharmacy": "Apoteket",
            "Sweetgreen": "Pinchos", "Whole Foods": "Coop", "AMC Theatres": "Filmstaden",
            "Con Edison": "Vattenfall", "Target": "Willys", "Ally Savings": "Sparkonto",
            "Delta Air Lines": "SAS", "Jiffy Lube": "Mekonomen"
        ]),
        "nb": StoreCaptureLanguage(currencyCode: "NOK", amountScale: 10, titles: [
            "Paycheck": "Lønn", "Direct deposit": "Overføring", "Rent": "Husleie", "Roth IRA": "Fondsparing",
            "Verizon": "Telenor", "Student Loan": "Studielån", "GEICO": "Gjensidige", "Trader Joe's": "Kiwi",
            "Chipotle": "Big Bite", "Shell": "Circle K", "Olive Garden": "Egon", "CVS Pharmacy": "Apotek 1",
            "Sweetgreen": "Joe & The Juice", "Whole Foods": "Meny", "AMC Theatres": "Odeon Kino",
            "Con Edison": "Fjordkraft", "Target": "Europris", "Ally Savings": "Sparekonto",
            "Delta Air Lines": "SAS", "Jiffy Lube": "Mekonomen", "Amazon": "Komplett"
        ])
    ]
}
#endif
