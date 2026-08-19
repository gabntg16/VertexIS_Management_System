# BranchOS — Centralized Branch Management System

A cross-platform Flutter app for managing multiple business branches with admin and branch-level access.

---

## 🚀 Features

### Admin (Super Admin)
- **Dashboard** — Overview: total branches, pending approvals, revenue, products
- **Orders** — View all orders from all branches; filter by status; approve/reject with reason
- **Branches** — Manage all branches; add new branch + manager account
- **Menu** — Add, edit, delete products (auto-syncs to all branches)
- **Announcements** — Publish announcements visible to all branches instantly

### Branch (Client Account)
- **Dashboard** — Personal stats: sales, pending orders, inventory; announcements feed
- **Orders** — Place product orders (select flavor + qty); upload payment proof
- **Inventory** — View current stock levels with low-stock warnings
- **Sales** — Record sales, view history and total revenue
- **Calendar** — View scheduled events and holidays

---

## 🏗️ Architecture

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── models.dart                    # All data models
├── services/
│   └── data_service.dart              # Central state + SharedPreferences persistence
├── utils/
│   └── theme.dart                     # Dark theme + color constants
├── widgets/
│   └── shared_widgets.dart            # Reusable UI components
└── screens/
    ├── auth/
    │   └── login_screen.dart          # Login with role detection
    ├── admin/
    │   ├── admin_shell.dart           # Nav rail (desktop) / bottom nav (mobile)
    │   ├── admin_dashboard.dart       # Stats + sales chart
    │   ├── admin_orders.dart          # All orders + approve/reject
    │   ├── admin_branches.dart        # Branch management
    │   ├── admin_menu.dart            # Product CRUD
    │   ├── admin_announcements.dart   # Publish announcements
    └── branch/
        ├── branch_shell.dart          # Bottom navigation
        ├── branch_dashboard.dart      # Stats + announcements feed
        ├── branch_orders.dart         # Create orders + upload payment
        ├── branch_inventory.dart      # Stock view
        ├── branch_sales.dart          # Record sales + history
        └── branch_calendar.dart       # Event calendar
```

---

## 📦 Tech Stack

| Layer | Technology |
| :--- | :--- |
| Framework | Flutter 3.10+ (Dart 3.0+) |
| State | Provider |
| Persistence | SharedPreferences (local JSON store) |
| Charts | fl_chart |
| Calendar | table_calendar |
| Fonts | google_fonts (DM Sans) |
| IDs | uuid |

---

## 🖥️ Responsive Layout

- **Mobile** — Bottom navigation bar
- **Tablet / Desktop (>700px)** — Navigation Rail (compact)
- **Wide Desktop (>1000px)** — Extended Navigation Rail with labels

---

## 🔐 Demo Credentials

| Role | Email | Password |
| :--- | :--- | :--- |
| Admin | admin@system.com | admin123 |
| Branch Manila | manila@branch.com | branch123 |
| Branch Cebu | cebu@branch.com | branch123 |
| Branch Davao | davao@branch.com | branch123 |

---

## ⚙️ Setup

### Prerequisites
- Flutter SDK ≥ 3.10.0
- Dart ≥ 3.0.0

### Run

```bash
# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release
```

---

## 🗄️ Database Structure (Modeled)

All data is stored locally via SharedPreferences as JSON.

Tables modeled:
- `users` — id, name, email, password, role, branchId
- `branches` — id, name, location
- `products` — id, name, flavor, price
- `orders` — id, branchId, status, totalAmount, createdAt
- `order_details` — orderId, productId, quantity, unitPrice
- `payments` — id, orderId, proofImagePath, status
- `inventory` — id, branchId, productId, stock
- `sales` — id, branchId, productId, quantity, total, date
- `announcements` — id, title, message, createdAt
- `events` — id, title, date, description

---

## 📝 Flow Summary

```
Branch → Create Order → Upload Payment Proof
        ↓
Admin → Review Order → Approve / Reject
        ↓
System updates status → Branch sees result
Approved → Inventory auto-updated
```
