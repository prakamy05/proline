# 🏋️‍♂️ ProLine Workspace Management System

**A beautiful, high-performance B2B SaaS Workspace Management System tailored for gym franchises, independent fitness centers, and fitness business owners.**

ProLine transforms complex administrative tasks into an approachable, user-centric dashboard — allowing you to focus less on spreadsheets and more on growing your community and tracking your business health.

![Flutter](https://img.shields.io/badge/Flutter-Cross--Platform-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-Express%20API-339933?logo=node.js&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active%20Development-yellow)

<p align="center">
  <img src="docs/screenshots/hero-banner.png" alt="ProLine Dashboard Overview" width="850"/>
  <br/>
  <sub><i>📌 Replace this with a hero screenshot or short GIF of your dashboard in action.</i></sub>
</p>

---

## 📌 Table of Contents

1. [Overview](#-overview)
2. [Features](#-features)
3. [Tech Stack](#-tech-stack)
4. [Installation & Getting Started](#-installation--getting-started)
5. [Architecture Overview](#-architecture-overview)
6. [Project File Structure](#-project-file-structure)
7. [Module Breakdown](#-module-breakdown)
8. [Database & Backend Deep Dive](#-database--backend-deep-dive)
9. [Project Scope & Roadmap](#-project-scope--roadmap)

---

# 🚀 Overview

Running a gym franchise means juggling member rosters, cash flow, staff schedules, and growth metrics — usually across three different spreadsheets. ProLine consolidates all of it into one clean, mobile-and-web-ready workspace, so owners and managers can spend less time on admin and more time on the floor.

ProLine is built for **single-owner, multi-branch** operations, with real-time syncing across devices and a security model that keeps every franchise branch's data isolated from the others.

---

# ✨ Features

### 👥 Approachable Membership Hub

<p align="center">
  <img src="docs/screenshots/members-tab.png" alt="Membership Hub Screenshot" width="700"/>
  <br/>
  <sub><i>📌 Add a screenshot of the members list/filter view here.</i></sub>
</p>

- **Smart Search & Filtering** — Instantly locate any member using their name, phone number, or Membership ID.
- **Dynamic Roster Sorts** — Effortlessly restructure your view based on what matters most in the moment (e.g., viewing upcoming expiries first, tracking members with pending dues, or looking at your newest signups).
- **State Locking (No More Lost Progress)** — Your searches and filter selections stay exactly as you left them, even when pulling down the screen to refresh data in the background.

### 💳 Transparent Finance Dashboard

<p align="center">
  <img src="docs/screenshots/finance-tab.png" alt="Finance Dashboard Screenshot" width="700"/>
  <br/>
  <sub><i>📌 Add a screenshot of the finance charts/sparklines here.</i></sub>
</p>

- **Tailored Financial Overviews** — View your true numbers (Revenue Collected, Operating Costs, and Due Amounts) mapped across flexible, self-contained time horizons (Today, Last 7 Days, Last 30 Days, Last 6 Months, or Last 1 Year).
- **Visual Trend Lines (Sparklines)** — Get an instant visual read on your performance directly inside the metric cards via colored, rolling trend indicator lines.
- **Slidable Cash Flow Timelines** — Track your long-term income and expense cycles with smooth, horizontally scrollable bar charts that allow you to slide back into previous months without lagging your device.

### 📈 Predictive Operation Trends

<p align="center">
  <img src="docs/screenshots/trends-tab.png" alt="Trends Dashboard Screenshot" width="700"/>
  <br/>
  <sub><i>📌 Add a screenshot of the trends/traffic density view here.</i></sub>
</p>

- **Roster Capacity Tracking** — See a structural timeline of your gym's total growth to check if your retention strategy is hitting the mark.
- **Signup Velocity** — Isolate and measure exact acquisition spikes week-by-week to see when your business is accelerating.
- **Traffic Density Maps** — Monitor checked-in profile histories to easily flag your busiest operating hours, helping you plan staff allocations and equipment floor distribution seamlessly.

---

# 🛠️ Tech Stack

ProLine relies on a secure, modern stack designed to maintain smooth experiences on both mobile devices and desktop web browsers:

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter | Powers the beautiful, cross-platform interface. Runs at a fluid 60 FPS on both mobile screens and modern web engines. |
| **State Architecture** | Provider | Acts as the central brain inside the device's memory — ensures every screen updates instantly, without stuttering, when data reloads or drops from the server. |
| **API Middleware** | Node.js & Express (`server.js`) | A lightweight, dedicated API gateway layer. Manages secure multi-tenant request routing, aggregates database responses, and enforces real-time synchronization safety before data reaches the app. |
| **Cloud Database** | Supabase (PostgreSQL) | Isolates multi-tenant franchise branch data securely, handles lightning-fast queries, and locks down customer profiles with advanced security rules. |
| **Encryption Layer** | Flutter Secure Storage | Keeps administrative profiles, workspace access credentials, and session tokens locked down safely on the local device. |

---

# 📥 Installation & Getting Started

Follow these steps to set up a local development environment for ProLine.

### Prerequisites

- Install the latest [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Install [Node.js](https://nodejs.org/) (includes `npm`) to run the backend engine.
- Set up an IDE like VS Code with the Flutter extension installed.

### Step 1 — Clone the Repository

```bash
git clone https://github.com/yourusername/proline.git
cd proline
```

### Step 2 — Boot the Backend API Server

```bash
cd backend
npm install
node server.js
```

Your server will spin up and listen on its designated local network port.

### Step 3 — Pull Frontend Dependencies

Open a new terminal window, navigate to your frontend directory, and download the required UI libraries:

```bash
cd ../frontend
flutter pub get
```

### Step 4 — Launch the Workspace Environment

Ensure your target physical device or emulator is running, then launch the project:

```bash
flutter run
```

---

# 🏗️ Architecture Overview

ProLine follows a clean three-tier architecture — the Flutter client never talks to the database directly. Every request is routed through the Node.js/Express middleware layer, which enforces tenant isolation and formats the response before it reaches the UI.

```text
┌─────────────────────────────┐
│   Flutter Client App        │
│  (Mobile + Web, Provider)   │
└──────────────┬───────────────┘
               │  HTTPS Requests
               ▼
┌─────────────────────────────┐
│  Node.js + Express Gateway  │
│         (server.js)         │
│  - Multi-tenant routing     │
│  - gym_id isolation filter  │
│  - Response aggregation     │
└──────────────┬───────────────┘
               │  Secure Queries
               ▼
┌─────────────────────────────┐
│   Supabase (PostgreSQL)     │
│  - payments ledger          │
│  - member status history    │
│  - branch/member/plan data  │
└─────────────────────────────┘
```

**Why route through a middleware layer instead of hitting Supabase directly?** It adds an essential layer of speed and defense — shielding the central database from raw client queries, enforcing branch-level data isolation by `gym_id`, and keeping client-side operations fast and lightweight.

---

# 📂 Project File Structure

The system is organized into a clean, **feature-first** directory module layout. This setup ensures that adding new tools or updating layouts can be done seamlessly without disturbing existing code.

```text
proline/
├── backend/                     # 🌐 Node.js API Middleware Layer
│   ├── package.json             # Backend dependencies & boot scripts
│   └── server.js                # Core API entry point, route definitions, & sync engine
│
└── frontend/                    # 📱 Flutter Cross-Platform Client Application
    └── lib/
        ├── core/                # 🔒 Global Foundations
        │   ├── theme/           # Visual style guide, fonts, and hex brand colors
        │   └── widgets/         # Bounded UI blocks (Cards, Stat views, loader wrappers)
        │
        ├── models/              # 📑 Blueprint Schemas
        │   ├── gym_model.dart   # Form structures for franchise branch properties
        │   ├── member_model.dart# Core structural definition fields for a member
        │   └── plan_model.dart  # Catalog configuration matrix for service tiers
        │
        ├── repositories/        # 📡 Cloud API Communication Channels
        │   ├── auth_repository.dart      # Handles user accounts, permissions, and security handshakes
        │   └── dashboard_repository.dart  # Synchronizes high-volume database payloads
        │
        ├── screens/              # 📱 User Interface Viewports
        │   ├── dashboard/         # Main layout container and bottom navigation controls
        │   ├── finance/           # finance_tab.dart (Slidable bar charts & trend lines)
        │   ├── members/           # members_tab.dart (Filtration roster list & card designs)
        │   └── trends/            # trends_tab.dart (Attendance tracking & velocity counters)
        │
        ├── state/                 # 🧠 Core Processing Engine
        │   └── gym_data_provider.dart  # App Single Source of Truth; stores data arrays in RAM
        │
        └── main.dart              # 🚀 Application Bootstrap Initialization Point
```

**Why this structure is preferred:** By separating the Interface Screens, the Backend API Engine (`server.js`), and the Central Brain (State Providers), the app stays incredibly easy to maintain. If you want to change how a card looks, you only touch the `screens/` folder — without worrying about breaking your backend architecture or database connections.

---

# 🧩 Module Breakdown

A quick reference for what lives where and why:

| Module | Responsibility |
|---|---|
| **`backend/server.js`** | The API gateway. Listens for app request handshakes, filters parameters by `gym_id` to enforce branch data isolation, and bundles sync operations into clean, fast JSON packages. |
| **`core/theme/`** | Centralized style guide — fonts, hex brand colors, spacing — so visual changes happen in one place. |
| **`core/widgets/`** | Reusable, bounded UI blocks (cards, stat views, loader wrappers) shared across screens. |
| **`models/`** | Typed blueprint schemas for gyms, members, and plans — the data contracts the rest of the app relies on. |
| **`repositories/`** | The communication layer between the app and the backend API — handles auth handshakes and dashboard data synchronization. |
| **`screens/`** | The actual user-facing viewports — dashboard shell, finance tab, members tab, and trends tab. |
| **`state/gym_data_provider.dart`** | The app's single source of truth in memory — every screen reads from and reacts to this provider. |
| **`main.dart`** | The application's bootstrap/entry point. |

---

# 💾 Database & Backend Deep Dive

ProLine structures information cleanly behind the scenes to keep business records highly optimized. Here's what the core server file and data logs represent:

### 1. The Backend Gateway Layer (`server.js`)

This is the middleware foundation of the application. Instead of forcing the mobile and web apps to make raw, heavy queries directly to the database, `server.js` acts as a secure coordinator. It listens for app request handshakes, safely filters parameters by `gym_id` to ensure branch data isolation, and bundles sync operations into clean, lightning-fast JSON packages.

> **Why it's preferred:** It adds an essential layer of speed and defense, shielding the central database while keeping client-side operations fast and lightweight.

### 2. Payments Ledger (`public.payments`)

This is the source of truth for realized liquid cash. Instead of guessing based on projections, every time a member hands over money (full payments, partial installments, or clearing off an old debt), a direct record is written here with the exact amount paid.

> **Why it's preferred:** It guarantees revenue reports show real cash in hand, not just theoretical promises.

### 3. Member Status History Audit (`public.member_status_history`)

An automated timeline log tracking every time a member's workspace status changes (e.g., transitioning from `ACTIVE` to `BLOCKED` or `EXPIRED`).

> **Why it's preferred:** It keeps a secure history of account actions, helping managers audit adjustments, spot member lifecycle habits, and avoid administrative errors.

---

# 🎯 Project Scope & Roadmap

### Current Project Scope

ProLine is explicitly designed to handle **single-owner, multi-branch** administrative tracking. It focuses on clean local interface components, fluid data calculations handled via the Node backend, and high-visibility financial performance charts.

### Future Scope & Roadmap

- **Offline Check-In Queueing System** — Allow staff to keep marking attendances and checking members in even if the gym temporarily loses internet connectivity, caching actions locally and syncing them through `server.js` once the connection returns.
- **Automatic WhatsApp & SMS Invoice Reminders** — Integrate automated background tasks into the server layer to instantly alert customers the moment a payment due date passes.
- **Member-Facing Mobile Companion App** — Introduce a lightweight secondary companion application where gym members can view their active plan details, track check-in streaks, and make payments directly through a secure mobile gateway.
