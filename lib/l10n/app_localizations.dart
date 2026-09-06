import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @app_name.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة نيكفا'**
  String get app_name;

  /// No description provided for @app_tagline.
  ///
  /// In ar, this message translates to:
  /// **'سوق المستلزمات الطبية'**
  String get app_tagline;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phone;

  /// No description provided for @account_type.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get account_type;

  /// No description provided for @cart.
  ///
  /// In ar, this message translates to:
  /// **'سلة التسوق'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get checkout;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @catalog.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get catalog;

  /// No description provided for @products.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get products;

  /// No description provided for @orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get orders;

  /// No description provided for @admin.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get admin;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @offline_warning.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get offline_warning;

  /// No description provided for @no_internet.
  ///
  /// In ar, this message translates to:
  /// **'بعض الميزات معطلة. يرجى التحقق من اتصالك.'**
  String get no_internet;

  /// No description provided for @try_again.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get try_again;

  /// No description provided for @add_to_cart.
  ///
  /// In ar, this message translates to:
  /// **'أضف إلى السلة'**
  String get add_to_cart;

  /// No description provided for @search_products.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن منتجات...'**
  String get search_products;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stock;

  /// No description provided for @order_placed.
  ///
  /// In ar, this message translates to:
  /// **'تم تقديم الطلب بنجاح'**
  String get order_placed;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get pending;

  /// No description provided for @confirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get confirmed;

  /// No description provided for @shipped.
  ///
  /// In ar, this message translates to:
  /// **'تم الشحن'**
  String get shipped;

  /// No description provided for @delivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @language_arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get language_arabic;

  /// No description provided for @language_french.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get language_french;

  /// No description provided for @individual.
  ///
  /// In ar, this message translates to:
  /// **'فرد'**
  String get individual;

  /// No description provided for @hospital.
  ///
  /// In ar, this message translates to:
  /// **'مستشفى'**
  String get hospital;

  /// No description provided for @laboratory.
  ///
  /// In ar, this message translates to:
  /// **'مختبر'**
  String get laboratory;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك'**
  String get welcome;

  /// No description provided for @featured_products.
  ///
  /// In ar, this message translates to:
  /// **'منتجات مميزة'**
  String get featured_products;

  /// No description provided for @browse_catalog.
  ///
  /// In ar, this message translates to:
  /// **'تصفح الكتالوج'**
  String get browse_catalog;

  /// No description provided for @failed_to_load_featured_products.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل المنتجات المميزة. يرجى التحقق من اتصالك بالإنترنت أو المحاولة لاحقاً.'**
  String get failed_to_load_featured_products;

  /// No description provided for @error_occurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error_occurred;

  /// No description provided for @something_went_wrong.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'**
  String get something_went_wrong;

  /// No description provided for @account_type_individual.
  ///
  /// In ar, this message translates to:
  /// **'فرد'**
  String get account_type_individual;

  /// No description provided for @account_type_hospital.
  ///
  /// In ar, this message translates to:
  /// **'مستشفى'**
  String get account_type_hospital;

  /// No description provided for @account_type_laboratory.
  ///
  /// In ar, this message translates to:
  /// **'مختبر'**
  String get account_type_laboratory;

  /// No description provided for @confirm_password.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirm_password;

  /// No description provided for @forgot_password.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgot_password;

  /// No description provided for @password_too_short.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تكون كلمة المرور 6 أحرف على الأقل'**
  String get password_too_short;

  /// No description provided for @passwords_dont_match.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get passwords_dont_match;

  /// No description provided for @email_already_exists.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجل بالفعل'**
  String get email_already_exists;

  /// No description provided for @invalid_credentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get invalid_credentials;

  /// No description provided for @network_error.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى'**
  String get network_error;

  /// No description provided for @registration_success.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح'**
  String get registration_success;

  /// No description provided for @session_expired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى'**
  String get session_expired;

  /// No description provided for @phone_required.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف مطلوب'**
  String get phone_required;

  /// No description provided for @phone_invalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف صحيح'**
  String get phone_invalid;

  /// No description provided for @login_success.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get login_success;

  /// No description provided for @logout_success.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الخروج'**
  String get logout_success;

  /// No description provided for @password_strength.
  ///
  /// In ar, this message translates to:
  /// **'قوة كلمة المرور'**
  String get password_strength;

  /// No description provided for @password_strength_weak.
  ///
  /// In ar, this message translates to:
  /// **'ضعيفة'**
  String get password_strength_weak;

  /// No description provided for @password_strength_medium.
  ///
  /// In ar, this message translates to:
  /// **'متوسطة'**
  String get password_strength_medium;

  /// No description provided for @password_strength_strong.
  ///
  /// In ar, this message translates to:
  /// **'قوية'**
  String get password_strength_strong;

  /// No description provided for @invalid_email.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get invalid_email;

  /// No description provided for @auth_signup_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء الحساب. يرجى المحاولة مرة أخرى'**
  String get auth_signup_failed;

  /// No description provided for @auth_login_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى'**
  String get auth_login_failed;

  /// No description provided for @auth_profile_not_created.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء الملف الشخصي. يرجى التواصل مع الدعم'**
  String get auth_profile_not_created;

  /// No description provided for @auth_profile_not_found.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي غير موجود. يرجى التواصل مع الدعم'**
  String get auth_profile_not_found;

  /// No description provided for @auth_signout_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الخروج. يرجى المحاولة مرة أخرى'**
  String get auth_signout_failed;

  /// No description provided for @dont_have_account.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get dont_have_account;

  /// No description provided for @already_have_account.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get already_have_account;

  /// No description provided for @no_account_yet.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً الآن'**
  String get no_account_yet;

  /// No description provided for @admin_panel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get admin_panel;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @customers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get customers;

  /// No description provided for @dashboard_overview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على لوحة التحكم'**
  String get dashboard_overview;

  /// No description provided for @total_products.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المنتجات'**
  String get total_products;

  /// No description provided for @pending_orders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات المعلقة'**
  String get pending_orders;

  /// No description provided for @total_revenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإيرادات'**
  String get total_revenue;

  /// No description provided for @active_customers.
  ///
  /// In ar, this message translates to:
  /// **'العملاء النشطون'**
  String get active_customers;

  /// No description provided for @recent_activity.
  ///
  /// In ar, this message translates to:
  /// **'النشاط الأخير'**
  String get recent_activity;

  /// No description provided for @view_all.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get view_all;

  /// No description provided for @new_order_received.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب جديد #1234'**
  String get new_order_received;

  /// No description provided for @product_updated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المنتج \"Nike Air Max\"'**
  String get product_updated;

  /// No description provided for @customer_registered.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل العميل John Doe'**
  String get customer_registered;

  /// No description provided for @inventory_low.
  ///
  /// In ar, this message translates to:
  /// **'المخزون منخفض: حذاء رياضي XL'**
  String get inventory_low;

  /// No description provided for @products_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المنتجات'**
  String get products_management;

  /// No description provided for @manage_product_catalog.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وتعديل وإدارة كتالوج المنتجات'**
  String get manage_product_catalog;

  /// No description provided for @add_new_product.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج جديد'**
  String get add_new_product;

  /// No description provided for @orders_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الطلبات'**
  String get orders_management;

  /// No description provided for @view_manage_orders.
  ///
  /// In ar, this message translates to:
  /// **'عرض وإدارة طلبات العملاء'**
  String get view_manage_orders;

  /// No description provided for @inventory_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المخزون'**
  String get inventory_management;

  /// No description provided for @track_stock_levels.
  ///
  /// In ar, this message translates to:
  /// **'تتبع مستويات المخزون وإدارته'**
  String get track_stock_levels;

  /// No description provided for @customers_management.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العملاء'**
  String get customers_management;

  /// No description provided for @view_manage_customers.
  ///
  /// In ar, this message translates to:
  /// **'عرض وإدارة حسابات العملاء'**
  String get view_manage_customers;

  /// No description provided for @configure_settings.
  ///
  /// In ar, this message translates to:
  /// **'تكوين إعدادات التطبيق'**
  String get configure_settings;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الفرعي'**
  String get subtotal;

  /// No description provided for @delivery_fee.
  ///
  /// In ar, this message translates to:
  /// **'رسوم التوصيل'**
  String get delivery_fee;

  /// No description provided for @free.
  ///
  /// In ar, this message translates to:
  /// **'مجاني'**
  String get free;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @item_removed.
  ///
  /// In ar, this message translates to:
  /// **'تم إزالة العنصر'**
  String get item_removed;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @login_to_checkout.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدخول لإتمام الطلب'**
  String get login_to_checkout;

  /// No description provided for @proceed_to_checkout.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الطلب'**
  String get proceed_to_checkout;

  /// No description provided for @only.
  ///
  /// In ar, this message translates to:
  /// **'فقط'**
  String get only;

  /// No description provided for @left.
  ///
  /// In ar, this message translates to:
  /// **'متبقي!'**
  String get left;

  /// No description provided for @out_of_stock.
  ///
  /// In ar, this message translates to:
  /// **'نفذ المخزون'**
  String get out_of_stock;

  /// No description provided for @remove_out_of_stock_items.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إزالة العناصر غير المتوفرة'**
  String get remove_out_of_stock_items;

  /// No description provided for @cart_is_empty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get cart_is_empty;

  /// No description provided for @start_shopping_message.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التسوق وتصفح منتجاتنا الطبية'**
  String get start_shopping_message;

  /// No description provided for @login_to_sync_cart.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدخول لمزامنة سلتك عبر أجهزتك'**
  String get login_to_sync_cart;

  /// No description provided for @order_details.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get order_details;

  /// No description provided for @order_number.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب'**
  String get order_number;

  /// No description provided for @order_date.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الطلب'**
  String get order_date;

  /// No description provided for @order_items.
  ///
  /// In ar, this message translates to:
  /// **'عناصر الطلب'**
  String get order_items;

  /// No description provided for @shipping_address.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الشحن'**
  String get shipping_address;

  /// No description provided for @payment_method.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get payment_method;

  /// No description provided for @cash_on_delivery.
  ///
  /// In ar, this message translates to:
  /// **'الدفع عند الاستلام'**
  String get cash_on_delivery;

  /// No description provided for @cod_description.
  ///
  /// In ar, this message translates to:
  /// **'ادفع نقداً عند استلام طلبك'**
  String get cod_description;

  /// No description provided for @cancel_order.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancel_order;

  /// No description provided for @cancel_order_confirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء هذا الطلب؟'**
  String get cancel_order_confirmation;

  /// No description provided for @order_cancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب'**
  String get order_cancelled;

  /// No description provided for @reorder.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الطلب'**
  String get reorder;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @all_orders.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all_orders;

  /// No description provided for @items.
  ///
  /// In ar, this message translates to:
  /// **'عناصر'**
  String get items;

  /// No description provided for @no_orders_yet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بعد'**
  String get no_orders_yet;

  /// No description provided for @no_orders_with_filter.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بهذه الحالة'**
  String get no_orders_with_filter;

  /// No description provided for @view_all_orders.
  ///
  /// In ar, this message translates to:
  /// **'عرض جميع الطلبات'**
  String get view_all_orders;

  /// No description provided for @confirmation.
  ///
  /// In ar, this message translates to:
  /// **'التأكيد'**
  String get confirmation;

  /// No description provided for @order_review.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الطلب'**
  String get order_review;

  /// No description provided for @full_name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get full_name;

  /// No description provided for @field_required.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get field_required;

  /// No description provided for @region.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة/الولاية'**
  String get region;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @street_address.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الشارع'**
  String get street_address;

  /// No description provided for @building_floor_optional.
  ///
  /// In ar, this message translates to:
  /// **'المبنى/الطابق (اختياري)'**
  String get building_floor_optional;

  /// No description provided for @save_address_future.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان للاستخدام القادم'**
  String get save_address_future;

  /// No description provided for @confirmation_message.
  ///
  /// In ar, this message translates to:
  /// **'سيتم توصيل طلبك قريباً. شكراً لتسوقك معنا!'**
  String get confirmation_message;

  /// No description provided for @view_orders.
  ///
  /// In ar, this message translates to:
  /// **'عرض الطلبات'**
  String get view_orders;

  /// No description provided for @continue_shopping.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التسوق'**
  String get continue_shopping;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @place_order.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب'**
  String get place_order;

  /// No description provided for @terms_acceptance.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على شروط الاستخدام وسياسة الخصوصية'**
  String get terms_acceptance;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @sku.
  ///
  /// In ar, this message translates to:
  /// **'رمز المنتج'**
  String get sku;

  /// No description provided for @update_status.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get update_status;

  /// No description provided for @no_products_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات'**
  String get no_products_found;

  /// No description provided for @no_orders_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get no_orders_found;

  /// No description provided for @no_customers_found.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء'**
  String get no_customers_found;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @order_status_updated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة الطلب'**
  String get order_status_updated;

  /// No description provided for @product_deleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المنتج'**
  String get product_deleted;

  /// No description provided for @delete_product_confirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا المنتج؟'**
  String get delete_product_confirmation;

  /// No description provided for @low_stock_warning.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get low_stock_warning;

  /// No description provided for @in_stock.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get in_stock;

  /// No description provided for @update_stock.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المخزون'**
  String get update_stock;

  /// No description provided for @customer_email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get customer_email;

  /// No description provided for @customer_phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get customer_phone;

  /// No description provided for @customer_role.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get customer_role;

  /// No description provided for @customer_since.
  ///
  /// In ar, this message translates to:
  /// **'عميل منذ'**
  String get customer_since;

  /// No description provided for @total_orders_count.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطلبات'**
  String get total_orders_count;

  /// No description provided for @admin_customers_title.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العملاء'**
  String get admin_customers_title;

  /// No description provided for @featured.
  ///
  /// In ar, this message translates to:
  /// **'مميز'**
  String get featured;

  /// No description provided for @not_featured.
  ///
  /// In ar, this message translates to:
  /// **'غير مميز'**
  String get not_featured;

  /// No description provided for @mark_as.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كـ'**
  String get mark_as;

  /// No description provided for @filter_by_status.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الحالة'**
  String get filter_by_status;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @status_pending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get status_pending;

  /// No description provided for @status_confirmed.
  ///
  /// In ar, this message translates to:
  /// **'مؤكد'**
  String get status_confirmed;

  /// No description provided for @status_shipped.
  ///
  /// In ar, this message translates to:
  /// **'تم الشحن'**
  String get status_shipped;

  /// No description provided for @status_delivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get status_delivered;

  /// No description provided for @status_cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get status_cancelled;

  /// No description provided for @low_stock_products.
  ///
  /// In ar, this message translates to:
  /// **'منتجات منخفضة المخزون'**
  String get low_stock_products;

  /// No description provided for @healthy_stock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون كافٍ'**
  String get healthy_stock;

  /// No description provided for @out_of_stock_products.
  ///
  /// In ar, this message translates to:
  /// **'منتجات نفذت'**
  String get out_of_stock_products;

  /// No description provided for @edit_product.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المنتج'**
  String get edit_product;

  /// No description provided for @product_name.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج'**
  String get product_name;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @image_url.
  ///
  /// In ar, this message translates to:
  /// **'رابط الصورة'**
  String get image_url;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @product_saved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المنتج'**
  String get product_saved;

  /// No description provided for @product_created.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء المنتج'**
  String get product_created;

  /// No description provided for @manage_categories.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الفئات'**
  String get manage_categories;

  /// No description provided for @add_category.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فئة'**
  String get add_category;

  /// No description provided for @edit_category.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفئة'**
  String get edit_category;

  /// No description provided for @parent_category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة الأم'**
  String get parent_category;

  /// No description provided for @no_categories_found.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فئات'**
  String get no_categories_found;

  /// No description provided for @delete_category_confirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الفئة؟ سيتم إعادة تعيين المنتجات المرتبطة إلى فئة أخرى.'**
  String get delete_category_confirmation;

  /// No description provided for @reassign_products_to.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين المنتجات إلى'**
  String get reassign_products_to;

  /// No description provided for @no_reassignment.
  ///
  /// In ar, this message translates to:
  /// **'عدم إعادة التعيين (حذف المنتجات)'**
  String get no_reassignment;

  /// No description provided for @upload_images.
  ///
  /// In ar, this message translates to:
  /// **'صور المنتج'**
  String get upload_images;

  /// No description provided for @save_changes.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get save_changes;

  /// No description provided for @order_status.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب'**
  String get order_status;

  /// No description provided for @none.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد'**
  String get none;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @my_profile.
  ///
  /// In ar, this message translates to:
  /// **'ملفي الشخصي'**
  String get my_profile;

  /// No description provided for @edit_profile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get edit_profile;

  /// No description provided for @member_since.
  ///
  /// In ar, this message translates to:
  /// **'عضو منذ'**
  String get member_since;

  /// No description provided for @profile_updated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الملف الشخصي'**
  String get profile_updated;

  /// No description provided for @profile_update_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث الملف الشخصي'**
  String get profile_update_failed;

  /// No description provided for @currency_symbol.
  ///
  /// In ar, this message translates to:
  /// **'FCFA'**
  String get currency_symbol;

  /// No description provided for @cancelled_status.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled_status;

  /// No description provided for @share_product.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة المنتج'**
  String get share_product;

  /// No description provided for @share_product_copied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط المنتج'**
  String get share_product_copied;

  /// No description provided for @password_reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get password_reset;

  /// No description provided for @password_reset_sent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'**
  String get password_reset_sent;

  /// No description provided for @password_reset_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال رابط إعادة تعيين كلمة المرور'**
  String get password_reset_failed;

  /// No description provided for @enter_email_for_reset.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني لتلقي رابط إعادة تعيين كلمة المرور'**
  String get enter_email_for_reset;

  /// No description provided for @send_reset_link.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط إعادة التعيين'**
  String get send_reset_link;

  /// No description provided for @reorder_success.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة عناصر الطلب إلى السلة'**
  String get reorder_success;

  /// No description provided for @reorder_failed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إعادة الطلب'**
  String get reorder_failed;

  /// No description provided for @cannot_delete_category_with_products.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الحذف: هناك منتجات مرتبطة بهذه الفئة. يرجى إعادة تعيينها إلى فئة أخرى أولاً.'**
  String get cannot_delete_category_with_products;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
