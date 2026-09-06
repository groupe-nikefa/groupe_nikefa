// Checkout screen — multi-step COD-only order flow.
//
// Step 1: Shipping Address form
// Step 2: Order Review with items, address, and payment method
// Step 3: Confirmation with success animation and order number

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/order.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;

  // Step 1: Shipping address form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingController = TextEditingController();
  bool _saveAddress = false;

  // Step 2: Terms acceptance
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _currentStep, l10n: l10n),

          // Step content
          Expanded(
            child: switch (_currentStep) {
              0 => _ShippingAddressStep(
                  formKey: _formKey,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  regionController: _regionController,
                  cityController: _cityController,
                  addressController: _addressController,
                  buildingController: _buildingController,
                  saveAddress: _saveAddress,
                  onSaveAddressChanged: (v) => setState(() => _saveAddress = v),
                ),
              1 => _OrderReviewStep(
                  items: ref.read(cartItemsProvider).valueOrNull ?? [],
                  name: _nameController.text,
                  phone: _phoneController.text,
                  region: _regionController.text,
                  city: _cityController.text,
                  address: _addressController.text,
                  building: _buildingController.text,
                  termsAccepted: _termsAccepted,
                  onTermsChanged: (v) => setState(() => _termsAccepted = v),
                  total: ref.read(cartTotalProvider),
                  l10n: l10n,
                ),
              2 => _ConfirmationStep(
                  order: ref.read(createOrderProvider).createdOrder,
                  l10n: l10n,
                ),
              _ => const SizedBox.shrink(),
            },
          ),

          // Navigation buttons
          _NavigationButtons(
            currentStep: _currentStep,
            onBack:
                _currentStep > 0 ? () => setState(() => _currentStep--) : null,
            onNext: _onNext,
            isLoading: ref.watch(createOrderProvider).isLoading,
            canProceed: _currentStep == 1 ? _termsAccepted : true,
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      _placeOrder();
    } else {
      context.go('/');
    }
  }

  Future<void> _placeOrder() async {
    final items = ref.read(cartItemsProvider).valueOrNull ?? [];
    if (items.isEmpty) return;

    final shippingAddress = <String, String>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'region': _regionController.text.trim(),
      'city': _cityController.text.trim(),
      'address': _addressController.text.trim(),
      if (_buildingController.text.trim().isNotEmpty)
        'building': _buildingController.text.trim(),
    };

    // Initialize notifications on first order.
    await NotificationService().initialize();

    final success = await ref.read(createOrderProvider.notifier).createOrder(
          shippingAddress: shippingAddress,
        );

    if (success && mounted) {
      setState(() => _currentStep = 2);
    } else if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.something_went_wrong),
            backgroundColor: AppColors.red),
      );
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Step indicator
// ──────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final AppLocalizations l10n;

  const _StepIndicator({required this.currentStep, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final steps = [l10n.shipping_address, l10n.order_review, l10n.confirmation];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= currentStep;
          final isCurrent = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.deepBlue : AppColors.surface,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.goldenYellow, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isActive && i < currentStep
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? AppColors.deepBlue
                            : AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < steps.length - 1)
                  const Expanded(child: Divider(indent: 4, endIndent: 4)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 1: Shipping Address
// ──────────────────────────────────────────────────────────────

class _ShippingAddressStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController regionController;
  final TextEditingController cityController;
  final TextEditingController addressController;
  final TextEditingController buildingController;
  final bool saveAddress;
  final ValueChanged<bool> onSaveAddressChanged;

  const _ShippingAddressStep({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.regionController,
    required this.cityController,
    required this.addressController,
    required this.buildingController,
    required this.saveAddress,
    required this.onSaveAddressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.shipping_address,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue)),
            const SizedBox(height: 16),
            TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.full_name),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.field_required
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phone),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.field_required
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: regionController,
                decoration: InputDecoration(labelText: l10n.region),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.field_required
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: cityController,
                decoration: InputDecoration(labelText: l10n.city),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.field_required
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: l10n.street_address),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.field_required
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: buildingController,
                decoration:
                    InputDecoration(labelText: l10n.building_floor_optional)),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: saveAddress,
              onChanged: (v) => onSaveAddressChanged(v ?? false),
              title: Text(l10n.save_address_future,
                  style: const TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 2: Order Review
// ──────────────────────────────────────────────────────────────

class _OrderReviewStep extends StatelessWidget {
  final List<CartItem> items;
  final String name, phone, region, city, address, building;
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;
  final double total;
  final AppLocalizations l10n;

  const _OrderReviewStep({
    required this.items,
    required this.name,
    required this.phone,
    required this.region,
    required this.city,
    required this.address,
    required this.building,
    required this.termsAccepted,
    required this.onTermsChanged,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final deliveryFee = total >= 50 ? 0.0 : 5.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipping address summary
          Text(l10n.shipping_address,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue)),
          const SizedBox(height: 8),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text(address),
                        if (building.isNotEmpty) Text(building),
                        Text('$city, $region'),
                        Text(phone,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ]))),
          const SizedBox(height: 20),

          // Items summary
          Text(l10n.order_items,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue)),
          const SizedBox(height: 8),
          ...items.map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      SizedBox(
                          width: 48,
                          height: 48,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: item.product?.primaryImageUrl.isNotEmpty ==
                                      true
                                  ? CachedNetworkImage(
                                      imageUrl: item.product!.primaryImageUrl,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.surface,
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 20,
                                          color: AppColors.textSecondary)))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(item.product?.getLocalizedName(locale) ?? '',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                                'x${item.quantity}  •  ${item.effectivePrice.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ])),
                      Text('${item.lineTotal.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ])),
              )),

          const SizedBox(height: 20),

          // Payment method
          Text(l10n.payment_method,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepBlue)),
          const SizedBox(height: 8),
          Card(
              child: ListTile(
            leading:
                const Icon(Icons.payments_outlined, color: AppColors.deepBlue),
            title: Text(l10n.cash_on_delivery),
            subtitle: Text(l10n.cod_description,
                style: const TextStyle(fontSize: 12)),
          )),

          const SizedBox(height: 20),

          // Total
          Card(
              color: AppColors.surface,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.subtotal),
                          Text('${total.toStringAsFixed(0)} FCFA')
                        ]),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.delivery_fee),
                          Text(deliveryFee == 0
                              ? l10n.free
                              : '${deliveryFee.toStringAsFixed(0)} FCFA')
                        ]),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.total,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              '${(total + deliveryFee).toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBlue,
                                  fontSize: 16))
                        ]),
                  ]))),

          const SizedBox(height: 16),

          // Terms checkbox
          CheckboxListTile(
            value: termsAccepted,
            onChanged: (v) => onTermsChanged(v ?? false),
            title: Text(l10n.terms_acceptance,
                style: const TextStyle(fontSize: 13)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Step 3: Confirmation
// ──────────────────────────────────────────────────────────────

class _ConfirmationStep extends StatelessWidget {
  final Order? order;
  final AppLocalizations l10n;

  const _ConfirmationStep({required this.order, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(l10n.order_placed,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepBlue),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (order != null) ...[
              Text('${l10n.order_number}: #${order!.shortId}',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
            ],
            Text(l10n.confirmation_message,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/orders'),
              child: Text(l10n.view_orders),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.continue_shopping),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Navigation buttons
// ──────────────────────────────────────────────────────────────

class _NavigationButtons extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLoading;
  final bool canProceed;
  final AppLocalizations l10n;

  const _NavigationButtons({
    required this.currentStep,
    this.onBack,
    required this.onNext,
    required this.isLoading,
    required this.canProceed,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
                child:
                    OutlinedButton(onPressed: onBack, child: Text(l10n.back))),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: (isLoading || !canProceed) ? null : onNext,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(currentStep == 1 ? l10n.place_order : l10n.next),
            ),
          ),
        ],
      ),
    );
  }
}
