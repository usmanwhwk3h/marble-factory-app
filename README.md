# Marble Factory Management System — Android Mobile App (Flutter)

A standalone, **100% offline-first Android mobile application (.apk)** built with **Flutter (Dart)** and local SQLite (`sqflite`). Designed specifically for marble factories, granite processing units, and stone yards to run directly inside mobile phones without depending on a laptop or internet connection.

---

## Architecture & Offline Database

- **Framework:** Flutter 3.x (Dart 3.x)
- **Local Database:** SQLite via `sqflite` and `path_provider` (stored securely in phone's internal storage: `/data/user/0/com.example.marble_factory_app/databases/marble_factory_mobile.db`)
- **Future Sync Ready:** All tables (`stock_items`, `customers`, `invoices`, `khata_entries`) contain:
  - `sync_status` (`0` = local unsynced, `1` = synced to central server/laptop/Supabase)
  - `updated_at` (ISO-8601 timestamp for conflict resolution during future bi-directional sync)
- **Camera & Gallery:** Uses `image_picker` to capture high-res photographs of stone slabs and veining.
- **WhatsApp Integration:** Uses `url_launcher` with pre-filled customer phone numbers and itemized receipts.
- **PDF & Printing:** Generates 80mm thermal and A4 slips using `pdf` and `printing`.

---

## 🛠️ Step-by-Step Instructions: How to Generate the Release APK

You have **two main ways** to generate the `.apk` file:
1. **Method A (Easiest — 100% Free Online Cloud Build via GitHub Actions)**: No Android Studio or Flutter needed on your laptop!
2. **Method B (Local Command Line)**: If you already have Flutter installed on your PC/Mac.

---

### Method A: Build APK Online with GitHub Actions (Zero Setup Required)

This repository includes a ready-to-use GitHub Actions workflow file at `.github/workflows/build_apk.yml`.

1. **Push this project to a GitHub Repository** (Public or Private):
   ```bash
   git init
   git add .
   git commit -m "Marble Factory Manager Flutter App"
   git remote add origin https://github.com/<your-username>/marble-factory-app.git
   git push -u origin main
   ```
2. On GitHub, click on the **"Actions"** tab at the top.
3. You will see the **"Build Offline Android APK"** workflow running automatically.
4. When it finishes in ~3-5 minutes, click on the completed run.
5. Under **Artifacts**, click on **`MarbleFactoryManager-Release-APK`** to download your ready-to-install `app-release.apk`!
6. Transfer the `.apk` to your Android phone via WhatsApp, Google Drive, or USB cable, tap on it, and install!

---

### Method B: Build Locally using Flutter CLI

If you have Flutter installed on your Windows, Mac, or Linux computer:

#### Step 1: Open Terminal in the Flutter folder
```bash
cd flutter_mobile_app
```

#### Step 2: Get Dependencies
```bash
flutter pub get
```

#### Step 3: Test on Emulator or Connected Android Phone (Optional)
```bash
flutter run
```

#### Step 4: Build the Standalone Release APK
```bash
flutter build apk --release --no-tree-shake-icons
```

#### Step 5: Locate your APK File
Once the build completes, your standalone APK file will be at:
```text
flutter_mobile_app/build/app/outputs/flutter-apk/app-release.apk
```
Copy this file to your phone and install it.

---

### Method C: Build Online with Codemagic (Alternative Cloud Build)

1. Go to [Codemagic.io](https://codemagic.io) and sign up with GitHub.
2. Select your repository.
3. Choose **Flutter App (Android)**.
4. Click **Start new build**.
5. Codemagic will build and email you the `.apk` file directly.

---

## 📱 Mobile App Features Breakdown

### 1. Dashboard Tab
- **Metric Cards:** Today's Sales, Month's Sales, Total Cash Collected, Customer Baaqi (Udhaar), Low Stock Alerts.
- **Quick Actions:**
  - `+ New Bill`: Opens the counter & field POS billing screen.
  - `+ Add Stock`: Adds slabs, cut tiles, or raw blocks with photo attachment.
  - `Record Wasooli`: Receives cash from a customer and reduces their Khata balance immediately.
- **Recent Dispatched Bills:** Tap any bill to view its JazzCash-style digital transaction slip or print PDF.

### 2. Multi-Category Stock Management
- **3 Categories:** Slabs / Thaan (تھان), Cut Tiles / Size Maal (سائز مال), and Raw Blocks (پتھر کے بلاک).
- **Photo Capture:** Take photo with phone camera or pick from gallery to inspect stone grain.
- **Smart Sq. Ft. Calculator:** Automatically calculates `Length (ft) × Height (ft) × Pieces` into Total Sq. Ft.
- **Low Stock Warnings:** Items at or below minimum threshold are highlighted with alert badges.

### 3. Fast Counter & Field Billing (POS)
- **Customer Auto-Selection:** Choose from existing debtors or type in a new customer name and WhatsApp phone.
- **Stock Item Auto-Suggest:** Select from local stone bundles, enter Sq. Ft. sold and rate.
- **Automatic Stock Deduction:** On bill completion, SQLite automatically subtracts sold square feet from stock in a single atomic transaction.
- **Charges & Split Payment:** Add loading (Mazdoori), freight/truck, and discounts. Choose Cash, Bank Transfer, or Add to Khata (Udhaar).

### 4. JazzCash Style Digital Receipt & WhatsApp Sharing
- Styled like mobile fintech slips (JazzCash/EasyPaisa) with status badges, transaction ID, customer details, and net payable.
- **One-Click WhatsApp Share:** Automatically formats an Urdu/English receipt with bill number, items, total, and customer balance, and launches WhatsApp with the customer's phone number pre-filled.
- **Print Slip:** Generates an 80mm thermal receipt or saves as PDF.

### 5. Customer Khata & Wasooli (Ledger)
- Full list of customers with current Baaqi balance.
- Detailed ledger showing all past invoice debits and wasooli credits.
- Instant "Record Wasooli" payment collection with immediate balance updates.
- One-tap WhatsApp payment reminder message.

### 6. Daily & Monthly Reports
- Filter sales records by **Today**, **This Month**, or **Custom Date Range**.
- Financial summaries of Revenue, Cash Inflows, and Udhaar Dispatched.
