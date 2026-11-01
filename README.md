# Pak Transfer (SwiftUI)

Demo wallet app: Send Money, Add Money, Mobile Load, Bill Payment, My QR / Scan QR,
Contacts, History + Receipt, PIN login, Profile. Har button kaam karta hai.
Demo mode mein koi asli paisa nahi hilta.

## Xcode mein chalane ke steps

1. Xcode kholein, **File > New > Project > iOS > App**.
   Product Name: `PakTransfer`, Interface: **SwiftUI**, Language: **Swift**.
2. Xcode ki bani hui `PakTransferApp.swift` aur `ContentView.swift` delete karein.
3. Is folder ke `App`, `Models`, `Services`, `Store`, `Views` folders ko Xcode ke project navigator
   mein drag karein (**Copy items if needed** aur **Create groups** tick karein).
4. Camera (QR scan) ke liye: Project > Target > **Info** tab > naya key
   `Privacy - Camera Usage Description` = `QR scan karne ke liye camera chahiye`.
5. Deployment target **iOS 17.0** ya zyada rakhein. Run karein (Cmd + R).

Pehli baar app khol kar account banayein, phir **Add Money** se demo balance daal kar test karein.
Simulator mein camera nahi hota, wahan Scan QR screen ka "text paste" wala option istemal karein
(My QR ka payload `pakpay://pay?phone=03XXXXXXXXX&name=Ali` jaisa hota hai).

## Asli payment API kahan jorni hai

Sab payments `Services/PaymentService.swift` ke `PaymentService` protocol se guzarti hain.

1. `RealPaymentService` ke 4 functions (sendMoney, mobileLoad, payBill, addMoney) mein apne backend ke calls likhein.
2. `App/PakTransferApp.swift` mein `MockPaymentService()` ki jagah `RealPaymentService(...)` laga dein.

Zaroori: merchant key/secret app ke andar na rakhein; app apne backend se baat kare, aur backend
provider ki API se. Balance, fees aur limits ka final faisla server par ho.

## Folder map

- `Models/` data types, fees, validation
- `Services/` payment protocol, demo service, asli API ka placeholder
- `Store/` AppStore (account, balance, history, contacts, local storage)
- `Views/` saari screens
