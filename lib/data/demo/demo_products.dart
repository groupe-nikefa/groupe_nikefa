// Demo products — attractive offline fallback catalog for sales demos.
//
// Shown on the home page when Supabase returns no featured products
// (empty database, no network, unconfigured backend). Lets a client
// immediately see a full, real-looking medical marketplace in XAF (FCFA).
//
// Demo IDs use the `demo-` prefix so the UI can distinguish them from
// real Supabase products (no detail-page fetch, display-only sheet).

import '../models/product.dart';

/// Returns `true` for demo-only products (display only, no backend).
bool isDemoProduct(Product product) => product.id.startsWith('demo-');

/// Curated demo catalog: 8 typical medical-supply products for Chad,
/// with French + Arabic names and prices in Central African CFA franc.
const List<Product> demoProducts = [
  Product(
    id: 'demo-stethoscope',
    sku: 'DEMO-STET-001',
    nameFr: 'Stéthoscope Numérique',
    nameAr: 'سماعة طبية رقمية',
    descriptionFr:
        'Stéthoscope numérique haute précision avec écran LCD pour la surveillance du rythme cardiaque.',
    descriptionAr:
        'سماعة طبية رقمية عالية الدقة مع شاشة LCD لمراقبة معدل ضربات القلب.',
    categoryId: 'demo-cat-equipement',
    basePrice: 45000,
    stock: 25,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1584982751601-97dcc096659c?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-tensiometre',
    sku: 'DEMO-TENS-002',
    nameFr: 'Tensiomètre Électronique',
    nameAr: 'جهاز قياس ضغط الدم',
    descriptionFr:
        'Tensiomètre électronique à brassard avec grand écran et mémoire pour 2 utilisateurs.',
    descriptionAr:
        'جهاز قياس ضغط الدم إلكتروني بسوار للذراع وشاشة كبيرة وذاكرة لمستخدمين.',
    categoryId: 'demo-cat-equipement',
    basePrice: 28500,
    stock: 40,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-gants',
    sku: 'DEMO-GLOV-003',
    nameFr: 'Gants Nitrile (Boîte de 100)',
    nameAr: 'قفازات نتريل (علبة 100)',
    descriptionFr:
        'Gants médicaux en nitrile, sans latex, stériles — boîte de 100 unités.',
    descriptionAr:
        'قفازات طبية من النتريل خالية من اللاتكس ومعقمة — علبة 100 قطعة.',
    categoryId: 'demo-cat-consommable',
    basePrice: 7500,
    stock: 500,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-seringues',
    sku: 'DEMO-SYRN-004',
    nameFr: 'Seringues Stériles 5ml (x50)',
    nameAr: 'حقن معقمة 5 مل (50 قطعة)',
    descriptionFr:
        'Seringues stériles à usage unique de 5 ml — boîte de 50 unités.',
    descriptionAr: 'حقن معقمة للاستخدام الواحد بسعة 5 مل — علبة 50 قطعة.',
    categoryId: 'demo-cat-consommable',
    basePrice: 4250,
    stock: 1000,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1632685061325-3f0f2c6a4a1e?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-microscope',
    sku: 'DEMO-MICR-005',
    nameFr: 'Microscope de Laboratoire',
    nameAr: 'مجهر مخبري',
    descriptionFr:
        'Microscope de laboratoire à fort grossissement avec éclairage LED, idéal pour hôpitaux et laboratoires.',
    descriptionAr:
        'مجهر مخبري عالي التكبير مع إضاءة LED، مثالي للمستشفيات والمختبرات.',
    categoryId: 'demo-cat-laboratoire',
    basePrice: 185000,
    stock: 8,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-masques',
    sku: 'DEMO-MASK-006',
    nameFr: 'Masques Chirurgicaux (x50)',
    nameAr: 'كمامات جراحية (50 قطعة)',
    descriptionFr:
        'Masques chirurgicaux 3 plis à haute filtration — boîte de 50 unités.',
    descriptionAr: 'كمامات جراحية بثلاث طبقات وترشيح عالٍ — علبة 50 قطعة.',
    categoryId: 'demo-cat-protection',
    basePrice: 5000,
    stock: 800,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-glucometre',
    sku: 'DEMO-GLUC-007',
    nameFr: 'Glucomètre + 50 Bandelettes',
    nameAr: 'جهاز قياس السكري + 50 شريط',
    descriptionFr:
        'Kit glucomètre avec 50 bandelettes et autopiqueur — résultat en 5 secondes.',
    descriptionAr:
        'جهاز قياس السكري مع 50 شريط اختبار وقلم وخز — نتيجة خلال 5 ثوانٍ.',
    categoryId: 'demo-cat-equipement',
    basePrice: 18000,
    stock: 60,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=60',
    ],
  ),
  Product(
    id: 'demo-blouse',
    sku: 'DEMO-BLOU-008',
    nameFr: 'Blouse Médicale Premium',
    nameAr: 'مريول طبي فاخر',
    descriptionFr:
        'Blouse médicale premium en coton, plusieurs tailles, broderie personnalisable.',
    descriptionAr: 'مريول طبي فاخر من القطن بمقاسات متعددة مع إمكانية التطريز.',
    categoryId: 'demo-cat-protection',
    basePrice: 12500,
    stock: 120,
    isFeatured: true,
    images: [
      'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=600&q=60',
    ],
  ),
];
