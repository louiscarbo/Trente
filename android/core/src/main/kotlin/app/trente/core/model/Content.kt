package app.trente.core.model

import app.trente.core.support.ExternalLinks

/** The texts here are English keys, resolved through `localized()` by the app. */
data class TrentePlusBenefit(
    val id: String,
    val title: String,
    val detail: String,
    val icon: BenefitIcon,
    val tint: BenefitTint
) {
    enum class BenefitIcon { REPEAT, PHOTO, PALETTE, HEART }

    enum class BenefitTint { BLUE, ORANGE, PURPLE, RED }

    companion object {
        private val automaticRecurring = TrentePlusBenefit(
            id = "automaticRecurring",
            title = "Automatic recurring transactions",
            detail = "Rent, salary, subscriptions: added automatically, without you having to think about it.",
            icon = BenefitIcon.REPEAT,
            tint = BenefitTint.BLUE
        )

        private val notesAndImages = TrentePlusBenefit(
            id = "notesAndImages",
            title = "Notes and images",
            detail = "Add a receipt, a photo or a note to your transactions.",
            icon = BenefitIcon.PHOTO,
            tint = BenefitTint.ORANGE
        )

        private val appIcons = TrentePlusBenefit(
            id = "appIcons",
            title = "App icons",
            detail = "Customize how Trente looks on your Home Screen.",
            icon = BenefitIcon.PALETTE,
            tint = BenefitTint.PURPLE
        )

        private val supportIndieDeveloper = TrentePlusBenefit(
            id = "supportIndieDeveloper",
            title = "Support an indie developer",
            detail = "Trente is designed and maintained entirely by one person.",
            icon = BenefitIcon.HEART,
            tint = BenefitTint.RED
        )

        val all: List<TrentePlusBenefit> = listOf(automaticRecurring, notesAndImages, appIcons, supportIndieDeveloper)
    }
}

data class Credit(val id: String, val title: String, val detail: String, val url: String?)

data class CreditSection(val id: String, val title: String, val credits: List<Credit>) {
    companion object {
        val all: List<CreditSection> = listOf(
            CreditSection(
                id = "illustrations",
                title = "Illustrations",
                credits = listOf(
                    Credit(
                        id = "piggySavings",
                        title = "“Piggy Savings” by Vectors Market",
                        detail = "From Noun Project, licensed under CC BY 3.0. Adapted for the app icon and the pig sticker.",
                        url = ExternalLinks.piggySavingsIcon
                    ),
                    Credit(
                        id = "financialStartup",
                        title = "“Financial Startup” by Vectors Market",
                        detail = "From Noun Project, licensed under CC BY 3.0. Used for the rocket sticker.",
                        url = ExternalLinks.financialStartupIcon
                    ),
                    Credit(
                        id = "ccBy3",
                        title = "Creative Commons Attribution 3.0",
                        detail = "The license of both illustrations.",
                        url = ExternalLinks.ccBy3License
                    )
                )
            ),
            CreditSection(
                id = "fiftyThirtyTwenty",
                title = "The 50/30/20 Rule",
                credits = listOf(
                    Credit(
                        id = "allYourWorth",
                        title = "All Your Worth (2005)",
                        detail = "Popularized by Elizabeth Warren and Amelia Warren Tyagi.",
                        url = null
                    )
                )
            ),
            CreditSection(
                id = "thanks",
                title = "Thanks",
                credits = listOf(
                    Credit(
                        id = "testers",
                        title = "TestFlight Testers",
                        detail = "Thanks to everyone who tested Trente on TestFlight.",
                        url = null
                    ),
                    Credit(
                        id = "trenteVingt",
                        title = "TrenteVingt",
                        detail = "Trente is the successor of TrenteVingt (2023).",
                        url = null
                    )
                )
            )
        )
    }
}

data class ProfileLink(val id: String, val title: String, val icon: Icon, val url: String) {
    enum class Icon { WEBSITE, LINKEDIN, GITHUB }
}

data class DeveloperProfile(
    val name: String,
    val greeting: String,
    val bio: String,
    val links: List<ProfileLink>
) {
    companion object {
        val louis = DeveloperProfile(
            name = "Louis Carbo Estaque",
            greeting = "Hi, I'm Louis 👋",
            bio = "I'm a French 🇫🇷 developer who loves building apps. Trente is the app I wished I had to follow the 50/30/20 rule. " +
                "Every suggestion helps, so feel free to write to me!",
            links = listOf(
                ProfileLink("website", "Website", ProfileLink.Icon.WEBSITE, ExternalLinks.developerWebsite),
                ProfileLink("linkedIn", "LinkedIn", ProfileLink.Icon.LINKEDIN, ExternalLinks.developerLinkedIn),
                ProfileLink("gitHub", "GitHub", ProfileLink.Icon.GITHUB, ExternalLinks.developerGitHub)
            )
        )
    }
}
