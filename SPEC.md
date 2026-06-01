# 📋 Technical Specification: GROUPE NIKEFA Multi-Platform Medical Marketplace
**Target Agent:** AI Full-Stack Developer  
**Project Type:** MVP v1 (Multi-Platform: Android, iOS, Web)  
**Date:** 2026  

---

## 1. 🎯 Project Overview
Build a production-ready, multi-platform e-commerce application for **GROUPE NIKEFA**, a medical supply company in Chad. The app connects individual customers, hospitals, and laboratories with medical equipment and consumables.

**Core Objectives:**
- Deliver a seamless shopping experience with RTL (Arabic) and LTR (French) support.
- Implement a secure, role-based admin dashboard within the app for inventory and order management.
- Ensure scalability, security, and maintainability using modern Flutter and Supabase patterns.

---

## 2. 🛠️ Technical Stack
| Layer | Technology | Justification |
|-------|-----------|---------------|
| **Frontend Framework** | Flutter 3.x (Dart) | Single codebase for Android, iOS, Web; excellent RTL support |
| **State Management** | Riverpod 2.x | Lightweight, testable, modern alternative to Provider/BLoC |
| **Routing** | go_router 12.x | Declarative routing with deep linking support for web/mobile |
| **Backend & Database** | Supabase (PostgreSQL) | Managed BaaS with Auth, Realtime, Storage, and Edge Functions |
| **Authentication** | Supabase Auth (Email/Password) | Secure, built-in user management with JWT |
| **File Storage** | Supabase Storage | Integrated image hosting with transformation capabilities |
| **Local Persistence** | Hive or SharedPreferences | Cache user sessions, cart state, and app settings |
| **Networking** | supabase_flutter SDK | Official, type-safe client for Flutter |
| **Crash Reporting** | Firebase Crashlytics | Production-grade error tracking (deferred unit testing) |
| **Localization** | flutter_gen + ARB files | Type-safe, scalable i18n with RTL auto-detection |

---

## 3. 🗂️ Project Structure (Feature-First Architecture)
```
lib/
├── main.dart                  # App entry point, Riverpod providers, go_router config
├── core/
│   ├── constants/            # App-wide constants (colors, strings, API keys)
│   ├── theme/                # ThemeData with brand colors (#002664, #FECB00, #C60C30)
│   ├── utils/                # Helpers (image compressor, date formatter, validators)
│   └── errors/               # Custom error classes and failure handling
├── features/
│   ├── auth/                 # Login, registration, profile setup, account type selection
│   ├── home/                 # Landing page, featured products, language switcher
│   ├── catalog/              # Product listing, search, filters, categories
│   ├── product_detail/       # Product specs, images, variants, add-to-cart
│   ├── cart/                 # Cart management (synced with Supabase on login)
│   ├── checkout/             # COD-only flow, shipping info, order confirmation
│   ├── orders/               # Order history, real-time status tracking
│   └── admin/                # Admin-only dashboard (product/order/inventory management)
├── data/
│   ├── models/               # Serializable data classes (Product, Order, Profile, etc.)
│   ├── repositories/         # Supabase-backed repo implementations
│   └── datasources/          # Remote (Supabase) and local (Hive) data sources
└── l10n/
    ├── app_ar.arb            # Arabic strings (RTL)
    └── app_fr.arb            # French strings (LTR)
```

---

## 4. 🗄️ Supabase Database Schema
### Tables
1. **`profiles`** (extends `auth.users`)
   ```sql
   id (uuid, PK, references auth.users.id)
   phone (text, unique, required)
   account_type (enum: 'individual', 'hospital', 'laboratory')
   role (enum: 'customer', 'admin', default 'customer')
   created_at (timestamptz)
   updated_at (timestamptz)
   ```

2. **`categories`**
   ```sql
   id (uuid, PK)
   name_ar (text)
   name_fr (text)
   slug (text, unique)
   parent_id (uuid, nullable, self-reference)
   ```

3. **`products`**
   ```sql
   id (uuid, PK)
   sku (text, unique)
   name_ar / name_fr (text)
   description_ar / description_fr (text)
   base_price (numeric)
   stock_quantity (integer)
   medical_classification (text[])
   category_id (uuid, FK)
   images (text[]) -- URLs from Supabase Storage
   variants (jsonb) -- size, model, packaging options
   bulk_pricing (jsonb) -- tiered pricing rules
   is_featured (boolean)
   created_at / updated_at (timestamptz)
   ```

4. **`orders`**
   ```sql
   id (uuid, PK)
   user_id (uuid, FK -> profiles.id)
   status (enum: 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled')
   total_amount (numeric)
   payment_method (enum: 'cod') -- MVP: COD only
   shipping_address (jsonb)
   created_at / updated_at (timestamptz)
   ```

5. **`order_items`**
   ```sql
   id (uuid, PK)
   order_id (uuid, FK)
   product_id (uuid, FK)
   quantity (integer)
   unit_price (numeric)
   variant_selection (jsonb, nullable)
   ```

6. **`cart_items`** (for synced cart)
   ```sql
   id (uuid, PK)
   user_id (uuid, FK)
   product_id (uuid, FK)
   quantity (integer)
   variant_selection (jsonb, nullable)
   updated_at (timestamptz)
   UNIQUE(user_id, product_id, variant_selection)
   ```

### Row Level Security (RLS) Policies
- **`profiles`**: Users can read/write only their own row; admins can read all.
- **`products`/`categories`**: Public read; admin write.
- **`orders`/`order_items`**: Users access only their orders; admins access all.
- **`cart_items`**: Users access only their cart items.

---

## 5. 🔐 Authentication & Authorization Flow
1. **Registration**:
   - Collect: email, password, phone, account_type.
   - Create auth user via `supabase.auth.signUp()`.
   - Insert corresponding row into `profiles` table (trigger or manual).
2. **Login**:
   - Email + password via `supabase.auth.signInWithPassword()`.
   - Fetch profile data to determine role and account_type.
3. **Session Management**:
   - Persist session using `supabase_flutter`'s built-in storage.
   - Auto-refresh tokens; handle token expiry gracefully.
4. **Role-Based UI**:
   - Use Riverpod provider to expose `currentUserRole`.
   - Conditionally render admin dashboard entry point.

---

## 6. 🧩 Feature Implementation Details
### 🌍 Localization & RTL
- Use `flutter_gen` for type-safe access to ARB strings.
- Set `localeResolutionCallback` to default to Arabic (`ar`) if device locale unsupported.
- Ensure all layouts use `Directionality` widget; test RTL on all screens.

### 🛒 Cart Synchronization
- Guest cart: stored locally (Hive).
- On login: merge local cart with server cart (Supabase), resolve conflicts by keeping latest `updated_at`.
- Post-login: all cart operations write directly to `cart_items` table with realtime subscription for cross-device sync.

### 🔄 Realtime Updates
- Subscribe to `orders` and `products` tables via Supabase Realtime.
- On `UPDATE` events: refresh relevant UI widgets (e.g., order status badge, stock counter).
- Debounce updates to avoid excessive rebuilds.

### 📦 Admin Dashboard (In-App)
- Route guard: `/admin/*` accessible only if `currentUserRole == 'admin'`.
- **Product Management**: Form with image picker (compress via `image_picker` + `flutter_image_compress` before upload to Supabase Storage).
- **Order Management**: List view with status dropdown; update triggers realtime notification to customer.
- **Inventory**: Low-stock alerts shown on dashboard; bulk update support.

### 🌐 Offline Handling
- App launches without internet.
- Show non-intrusive banner: "No internet connection. Some features disabled."
- Disable network-dependent actions (search new products, checkout) until reconnected.
- Use connectivity_plus package to detect network changes.

---

## 7. 🎨 UI/UX & Branding Guidelines
- **Colors**: Use `ThemeData` extensions for `nikefaBlue`, `nikefaYellow`, `nikefaRed`.
- **Typography**: System fonts with Arabic fallback (e.g., `Noto Sans Arabic`).
- **Icons**: Use `lucide_icons` or `flutter_iconly` for medical-style iconography.
- **Responsive**: Use `LayoutBuilder` and `MediaQuery` to adapt grids/cards for mobile/web.
- **Loading States**: Skeleton loaders for product lists; shimmer effects for images.

---

## 8. 🔒 Security & Compliance
- **API Calls**: All via Supabase client (automatically uses HTTPS and JWT).
- **Sensitive Data**: Never log tokens or PII; use `flutter_secure_storage` if extra local encryption needed.
- **Legal Pages**: 
  - AI generates `privacy_policy.md` and `terms_of_service.md` (English/Arabic/French).
  - User hosts these on WordPress (`nikefa.net/privacy`, `nikefa.net/terms`).
  - App links to these URLs in settings and checkout screens.

---

## 9. 🚀 Deployment & Environment Setup
### Environment Variables (`.env.example`)
```env
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
APP_NAME=GROUPE NIKEFA
SUPPORT_EMAIL=support@nikefa.net
PRIVACY_POLICY_URL=https://nikefa.net/privacy
TERMS_URL=https://nikefa.net/terms
```

### Build Commands
```bash
# Web
flutter build web --release --base-href "/app/"

# Android
flutter build apk --release --split-per-abi

# iOS (requires macOS)
flutter build ios --release
```

### Supabase Setup Instructions
1. Create new Supabase project.
2. Run SQL migrations (provided in `/supabase/migrations`).
3. Enable Email auth in Supabase Dashboard.
4. Create Storage bucket `product-images` with public read, authenticated write.
5. Set up RLS policies as defined in Section 4.

---

## 10. ✅ Deliverables Checklist
- [ ] Full Flutter source code with feature-modular architecture
- [ ] Supabase SQL schema + RLS policies + migration scripts
- [ ] Seed data script (admin user, sample products/categories)
- [ ] Generated legal texts (Privacy Policy, Terms) in AR/FR/EN
- [ ] README.md with:
  - Setup instructions (Flutter, Supabase, env vars)
  - Build & deploy commands for Android/iOS/Web
  - Admin account credentials for testing
- [ ] Basic Crashlytics integration (Firebase setup guide included)
- [ ] All code commented in **Standard Technical English**
- [ ] Git commit messages follow conventional commits (`feat:`, `fix:`, `chore:`)

---

## 11. 📝 Notes for the AI Agent
- Prioritize **readability and maintainability** over premature optimization.
- Use **Riverpod generators** (`@riverpod`) for boilerplate reduction.
- Implement **error boundaries** and user-friendly error messages (localized).
- Test RTL layout thoroughly on both mobile and web targets.
- Assume the user is a **beginner**; include clear inline comments explaining non-obvious logic.
- Defer writing unit/widget tests to v2; focus on **manual testing checklist** for MVP.

***


