<div align="center">

<img src="assets/laucher_icon_img/In%20use/Finzo%20Logo.png" alt="Finzo offline personal finance app logo" width="112" />

# Finzo

**Offline personal finance manager, expense tracker, budget planner, loan tracker, credit card tracker, and investment tracker built with Flutter.**

[![Flutter](https://img.shields.io/badge/Flutter-mobile%20app-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11%2B-0175C2?logo=dart)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/Local%20database-SQLite-003B57?logo=sqlite)](https://www.sqlite.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Made by AHS Mobile Labs](https://img.shields.io/badge/AHS%20Mobile%20Labs-Finzo-111827?logo=github)](https://github.com/AHS-Mobile-Labs)

Finzo is a private, offline-first money manager for people who want to track accounts, spending, budgets, cashflow, loans, credit cards, and investments without depending on a cloud account.

[Features](#features) | [Screenshots](#screenshots) | [Download](#download) | [Install](#install) | [Tech Stack](#tech-stack) | [Contributing](#contributing)

</div>

## About

Finzo is a Flutter personal finance app designed for local finance books. It stores your money data in a local SQLite `.books.db` file, supports multiple finance books, and keeps daily money tracking fast with a dark, mobile-first interface.

Use Finzo as an offline expense tracker, income tracker, account balance manager, budget planner, cashflow analytics dashboard, loan EMI tracker, credit card utilization tracker, and investment portfolio tracker.

## Features

- **Offline finance books**: create, import, switch, and delete local `.books.db` finance books.
- **Expense and income tracking**: add transactions with account, category, date, notes, and search filters.
- **Account management**: manage cash, bank accounts, wallets, and transfers between accounts.
- **Monthly budget planner**: set category budgets, monitor spending, and see remaining budget.
- **Finance dashboard**: review net worth, account balance, investments, savings rate, projected spend, and cashflow trends.
- **Analytics and reports**: view six-month income/expense trends, category spend drilldowns, and financial health score.
- **Loan tracker**: track principal, outstanding amount, interest rate, tenure, EMI, EMI day, and optional auto EMI entries.
- **Credit card tracker**: monitor credit limits, used amount, available credit, billing day, due day, and utilization.
- **Investment tracker**: track portfolio value, invested amount, current value, return amount, return percentage, units, and prices.
- **Currency support**: choose from supported currencies for localized money formatting.
- **Private by default**: no cloud account is required for everyday personal finance tracking.

## Screenshots

<div align="center">

| Dashboard | Transactions | Budgets |
| --- | --- | --- |
| <img src="assets/github-img/%231/Screenshot_20260602_081054.jpg" alt="Finzo offline personal finance dashboard with net worth, savings rate, budget usage and cashflow chart" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081058.jpg" alt="Finzo expense tracker transactions screen with income expense transfer filters and search" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081100.jpg" alt="Finzo monthly budget planner with category budget usage and remaining amount" width="230" /> |

| Analytics Overview | Category Analytics | Health Score |
| --- | --- | --- |
| <img src="assets/github-img/%231/Screenshot_20260602_081105.jpg" alt="Finzo finance analytics overview with monthly income expense savings rate projection and six month trend" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081108.jpg" alt="Finzo category spending analytics with donut chart and category drilldown" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081111.jpg" alt="Finzo financial health score based on savings rate budget usage debt pressure daily pace and net worth" width="230" /> |

| Accounts | Investments | Settings |
| --- | --- | --- |
| <img src="assets/github-img/%231/Screenshot_20260602_081114.jpg" alt="Finzo account balance manager with cash and bank account net worth summary" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081133.jpg" alt="Finzo investment portfolio tracker with portfolio value invested amount and returns" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081143.jpg" alt="Finzo settings screen with profile currency local database path switch book create book and import book" width="230" /> |

| Credit Cards | Add Loan | Add Investment |
| --- | --- | --- |
| <img src="assets/github-img/%231/Screenshot_20260602_081119.jpg" alt="Finzo credit card tracker screen for adding credit card name and limit" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081128.jpg" alt="Finzo loan tracker form with principal amount interest tenure EMI auto EMI and account selection" width="230" /> | <img src="assets/github-img/%231/Screenshot_20260602_081136.jpg" alt="Finzo add investment form for mutual funds stocks gold invested amount current value units prices and notes" width="230" /> |

</div>

## Download

Download the latest release or get it from a supported store:

<div align="center">

<a href="https://github.com/AHS-Mobile-Labs/finzo/releases/latest">
  <img alt="Download from GitHub" src="assets/other/readme asset/badge_github.png" height="40" />
</a>
&nbsp;
<a href="#">
  <img alt="Get it on Google Play" src="assets/other/readme%20asset/GetItOnGooglePlay_Badge_Web_color_English.svg" height="40" />
</a>
&nbsp;
<a href="https://indusapp.store/4i6tw1m6">
  <img alt="Get it on Indus Appstore" src="https://docstore.indusappstore.com/public/external/developerdashboard-static/badge-black-background-english.png" height="40" />
</a>

<sub>Google Play coming soon &nbsp;·&nbsp; 🇮🇳 IndusAppStore is available for Indian users only</sub>

</div>

## Install

### Requirements

- Flutter SDK compatible with Dart `^3.11.1`
- Android SDK for Android builds
- Xcode for iOS builds on macOS

### Run Locally

```bash
git clone https://github.com/AHS-Mobile-Labs/finzo.git
cd finzo
flutter pub get
flutter run
```

### Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Tech Stack

- **Framework**: Flutter and Dart
- **State management**: Provider
- **Local database**: SQLite with `sqflite`
- **Charts**: `fl_chart`
- **Formatting**: `intl`
- **Animations**: `flutter_animate`
- **Files and storage**: `path_provider` and `file_picker`
- **Utilities**: `uuid`, `google_fonts`, `url_launcher`

## Project Structure

```text
finzo/
|-- lib/
|   |-- main.dart
|   |-- models/
|   |-- providers/
|   |-- screens/
|   |-- services/
|   |-- utils/
|   `-- widgets/
|-- assets/
|   |-- github-img/
|   `-- laucher_icon_img/
|-- android/
|-- ios/
|-- pubspec.yaml
`-- README.md
```

## SEO Keywords

Finzo, Flutter finance app, offline personal finance app, personal finance manager, expense tracker app, income tracker, budget planner app, money manager app, cashflow analytics app, SQLite finance app, loan tracker, EMI tracker, credit card tracker, investment tracker, net worth tracker, Android finance app, iOS finance app, private finance app.

## Contributing

Contributions are welcome. To contribute:

1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Run formatting and tests where applicable.
5. Open a pull request.

## Connect

- Email: [ahsmobilelabs@gmail.com](mailto:ahsmobilelabs@gmail.com)
- GitHub: [AHS-Mobile-Labs](https://github.com/AHS-Mobile-Labs)
- Instagram: [@ahsmobilelabs](https://www.instagram.com/ahsmobilelabs)
- YouTube: [@AHSMobileLabs](https://www.youtube.com/@AHSMobileLabs)
- X: [@ahsmobilelabs](https://x.com/ahsmobilelabs)

## License

Finzo is released under the [MIT License](LICENSE).

<div align="center">

**Made by AHS Mobile Labs**

[Back to top](#finzo)

</div>
