import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_field.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../../core/widgets/common.dart';
import '../extras/extras_repository.dart';
import '../wallet/wallet_repository.dart';

/// Shop — Diamond top-up + gaming products. Powered by NeXdEvE.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/shop/orders'),
            icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryHi),
            label: Text('My Orders', style: AppText.bodyStrong.copyWith(color: AppColors.primaryHi)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppText.button,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.diamond_rounded, size: 20), text: 'DIAMOND'),
            Tab(icon: Icon(Icons.qr_code_2_rounded, size: 20), text: 'DIGITAL CODES'),
            Tab(icon: Icon(Icons.shopping_bag_rounded, size: 20), text: 'PRODUCTS'),
          ],
        ),
      ),
      body: BzBackground(
        child: TabBarView(controller: _tabs, children: const [
          _ShopGrid(kind: 'diamond'),
          _ShopGrid(kind: 'digital_code'),
          _ShopGrid(kind: 'product'),
        ]),
      ),
    );
  }
}

class _ShopGrid extends ConsumerWidget {
  const _ShopGrid({required this.kind});
  final String kind;

  Widget _buildContent(Map<String, dynamic> d) {
    final items = (d['items'] as List).cast<Map>().map((e) => e.cast<String, dynamic>()).toList();
    if (d['enabled'] != true) {
      return ListView(children: const [BzEmpty(title: 'Shop is closed', message: 'Please check back soon.', icon: Icons.store_rounded)]);
    }
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _WalletStrip(total: d['wallet_total'], kind: kind)),
      if (items.isEmpty)
        const SliverToBoxAdapter(child: BzEmpty(title: 'No items yet', message: 'New items are coming soon.', icon: Icons.inventory_2_rounded))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: (kind == 'diamond' || kind == 'digital_code') ? 0.86 : 0.70,
            ),
            delegate: SliverChildBuilderDelegate(
              (c, i) => _ItemCard(item: items[i], shop: d).stagger(i),
              childCount: items.length,
            ),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(shopProvider(kind));
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(shopProvider(kind)),
      child: data.valueOrNull != null
          ? _buildContent(data.value!)
          : data.when(
              loading: () => const BzSkeletonList(itemHeight: 120, count: 4),
              error: (e, _) => ListView(children: [BzError(message: '$e', onRetry: () => ref.invalidate(shopProvider(kind)))]),
              data: (d) => _buildContent(d),
            ),
    );
  }
}

class _WalletStrip extends StatelessWidget {
  const _WalletStrip({required this.total, required this.kind});
  final dynamic total;
  final String kind;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: .22), AppColors.card]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: .35)),
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryHi),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your wallet', style: AppText.bodyS),
          Text(Fmt.taka(total), style: AppText.numL.copyWith(fontSize: 20)),
        ])),
        Text(kind == 'diamond' ? 'Instant top-up\nto your UID' : 'Delivery all\nover Bangladesh',
            textAlign: TextAlign.right, style: AppText.bodyS.copyWith(height: 1.3)),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.shop});
  final Map<String, dynamic> item;
  final Map<String, dynamic> shop;

  @override
  Widget build(BuildContext context) {
    final diamond = item['kind'] == 'diamond';
    final inStock = item['in_stock'] == true;
    final img = item['image_url'] as String?;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: inStock ? () => showBuySheet(context, item, shop) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                if (img != null && img.isNotEmpty)
                  CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, fadeInDuration: const Duration(milliseconds: 200),
                      errorWidget: (_, __, ___) => _placeholder(diamond))
                else
                  _placeholder(diamond),
                if (item['old_price'] != null)
                  Positioned(top: 8, left: 8, child: StatusPill('SALE', color: AppColors.primary)),
                if (!inStock)
                  Container(color: Colors.black54, alignment: Alignment.center,
                      child: Text('OUT OF STOCK', style: AppText.label.copyWith(color: Colors.white))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(height: 1.25)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(Fmt.takaShort(item['price']), style: AppText.numM.copyWith(color: AppColors.primaryHi, fontSize: 16)),
                  if (item['old_price'] != null) ...[
                    const SizedBox(width: 6),
                    Text(Fmt.takaShort(item['old_price']),
                        style: AppText.bodyS.copyWith(decoration: TextDecoration.lineThrough, color: AppColors.textMuted)),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder(bool diamond) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: .35), AppColors.card], radius: .9),
        ),
        child: Icon(diamond ? Icons.diamond_rounded : Icons.headphones_rounded, size: 54, color: AppColors.primaryHi),
      );
}

Future<void> showBuySheet(BuildContext context, Map<String, dynamic> item, Map<String, dynamic> shop) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BuySheet(item: item, shop: shop),
  );
}

class _BuySheet extends ConsumerStatefulWidget {
  const _BuySheet({required this.item, required this.shop});
  final Map<String, dynamic> item;
  final Map<String, dynamic> shop;
  @override
  ConsumerState<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends ConsumerState<_BuySheet> {
  final _uid = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _idem = newIdem();
  int _qty = 1;
  String _pay = 'wallet';
  bool _busy = false;
  Map<String, String> _errs = {};

  bool get _diamond => widget.item['kind'] == 'diamond';
  bool get _digitalCode => widget.item['kind'] == 'digital_code';
  bool get _physical => widget.item['kind'] == 'product';
  double get _price => double.tryParse('${widget.item['price']}') ?? 0;
  double get _delivery => (_diamond || _digitalCode) ? 0 : (double.tryParse('${widget.shop['delivery_charge']}') ?? 0);
  double get _total => _price * _qty + _delivery;
  double get _payNow => _pay == 'cod' ? _delivery : _total;

  @override
  void dispose() {
    for (final c in [_uid, _name, _phone, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final errs = <String, String>{};
    if (_diamond && _uid.text.trim().length < 5) errs['uid'] = 'Enter your game UID';
    if (_physical) {
      if (_name.text.trim().length < 3) errs['name'] = 'Enter your full name';
      if (!RegExp(r'^01\d{9}$').hasMatch(_phone.text.trim())) errs['phone'] = '11-digit BD number';
      if (_address.text.trim().length < 15) errs['address'] = 'Village/area, thana, district';
    }
    setState(() => _errs = errs);
    if (errs.isNotEmpty) return;

    setState(() => _busy = true);
    HapticFeedback.lightImpact();
    try {
      final r = await ref.read(extrasRepoProvider).order({
        'item_id': widget.item['id'],
        'qty': _qty,
        'idempotency_key': _idem,
        if (_diamond) 'game_uid': _uid.text.trim(),
        if (_physical) ...{
          'payment': _pay,
          'full_name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
        },
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      ref.read(extrasRefreshProvider.notifier).state++;
      ref.read(walletRefreshProvider.notifier).state++;
      if (!mounted) return;
      Navigator.pop(context);
      if (r['delivered_code'] != null) {
        _showCodeDialog(context, '${r['delivered_code']}');
      } else {
        showSnack(context, '✅ ${r['message'] ?? 'Order placed'}', kind: SnackKind.success);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxQ = (widget.item['max_per_order'] as num?)?.toInt() ?? 10;
    final cod = widget.shop['cod_enabled'] == true;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(9)))),
          const SizedBox(height: 16),
          Row(children: [
            Icon(_diamond ? Icons.diamond_rounded : Icons.shopping_bag_rounded, color: AppColors.primaryHi),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.item['title'] ?? '', style: AppText.h3)),
          ]),
          if ((widget.item['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(widget.item['description'], style: AppText.bodyS.copyWith(height: 1.5)),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Text('Quantity', style: AppText.bodyStrong),
            const Spacer(),
            _qtyBtn(Icons.remove_rounded, _qty > 1 ? () => setState(() => _qty--) : null),
            SizedBox(width: 44, child: Center(child: Text('$_qty', style: AppText.numL.copyWith(fontSize: 20)))),
            _qtyBtn(Icons.add_rounded, _qty < maxQ ? () => setState(() => _qty++) : null),
          ]),
          const SizedBox(height: 16),
          if (_diamond)
            BzField(controller: _uid, label: 'GAME UID', hint: 'Your Free Fire UID', icon: Icons.badge_rounded,
                keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], errorText: _errs['uid'])
          else if (_digitalCode)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.cyan, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ Instant Code Delivery! Your redeem code will be unlocked immediately upon order confirmation.',
                      style: AppText.bodyS.copyWith(color: AppColors.cyan, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            BzField(controller: _name, label: 'FULL NAME', hint: 'Your full name', icon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words, errorText: _errs['name']),
            const SizedBox(height: 12),
            BzField(controller: _phone, label: 'CONTACT NUMBER', hint: '01XXXXXXXXX', icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone, maxLength: 11, inputFormatters: [FilteringTextInputFormatter.digitsOnly], errorText: _errs['phone']),
            const SizedBox(height: 12),
            BzField(controller: _address, label: 'FULL ADDRESS', hint: 'Village/area, thana, district', icon: Icons.location_on_rounded, errorText: _errs['address']),
            const SizedBox(height: 14),
            Text('PAYMENT', style: AppText.label),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _payOpt('wallet', 'Wallet', 'Pay now', Icons.account_balance_wallet_rounded)),
              if (cod) ...[
                const SizedBox(width: 10),
                Expanded(child: _payOpt('cod', 'Cash on Delivery', 'Delivery charge now', Icons.local_shipping_rounded)),
              ],
            ]),
          ],
          const SizedBox(height: 12),
          BzField(controller: _note, label: 'NOTE (OPTIONAL)', hint: _diamond ? 'Server / anything else' : (_digitalCode ? 'Optional note' : 'Color / size / instruction'), icon: Icons.edit_note_rounded),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
            child: Column(children: [
              KV('Subtotal', Fmt.taka(_price * _qty)),
              if (_physical) KV('Delivery', Fmt.taka(_delivery)),
              const Divider(height: 18),
              KV('Total', Fmt.taka(_total), valueStyle: AppText.numM.copyWith(fontSize: 16)),
              if (_pay == 'cod') KV('Pay on delivery', Fmt.taka(_total - _payNow)),
              KV('Pay now from wallet', Fmt.taka(_payNow), valueStyle: AppText.numM.copyWith(color: AppColors.primaryHi, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 18),
          BzButton(label: 'CONFIRM ORDER', icon: Icons.check_circle_rounded, loading: _busy, onPressed: _busy ? null : _submit),
        ]),
      ),
    );
  }

  Widget _qtyBtn(IconData i, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.cardHi, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: Icon(i, size: 18, color: onTap == null ? AppColors.textFaint : AppColors.text),
        ),
      );

  Widget _payOpt(String v, String t, String s, IconData i) {
    final on = _pay == v;
    return GestureDetector(
      onTap: () => setState(() => _pay = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? AppColors.primary.withValues(alpha: .14) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? AppColors.primary : AppColors.line, width: on ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(i, size: 20, color: on ? AppColors.primaryHi : AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: AppText.bodyStrong.copyWith(fontSize: 12.5)),
            Text(s, style: AppText.tiny),
          ])),
        ]),
      ),
    );
  }
}

/// My shop orders
class ShopOrdersScreen extends ConsumerWidget {
  const ShopOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(shopOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: BzBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(shopOrdersProvider),
          child: orders.when(
            loading: () => const BzSkeletonList(itemHeight: 90, count: 5),
            error: (e, _) => ListView(children: [BzError(message: '$e', onRetry: () => ref.invalidate(shopOrdersProvider))]),
            data: (list) => list.isEmpty
                ? ListView(children: const [BzEmpty(title: 'No orders yet', message: 'Your diamond and product orders will show here.', icon: Icons.receipt_long_rounded)])
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _OrderTile(o: list[i]).stagger(i),
                  ),
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.o});
  final Map<String, dynamic> o;
  @override
  Widget build(BuildContext context) {
    final status = '${o['status']}';
    final color = switch (status) {
      'completed' => AppColors.success,
      'cancelled' => AppColors.danger,
      'processing' => AppColors.info,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(o['kind'] == 'diamond' ? Icons.diamond_rounded : Icons.shopping_bag_rounded, color: AppColors.primaryHi, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('${o['title']} ×${o['qty']}', style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
          StatusPill(status.toUpperCase(), color: color),
        ]),
        const SizedBox(height: 8),
        Text([
          o['ref'],
          Fmt.taka(o['total']),
          if (o['payment'] == 'cod') 'COD',
          if (o['game_uid'] != null) 'UID ${o['game_uid']}',
        ].join('  ·  '), style: AppText.bodyS),
        if ((o['admin_note'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Note: ${o['admin_note']}', style: AppText.bodyS.copyWith(color: AppColors.textDim)),
        ],
        if (o['delivered_code'] != null && '${o['delivered_code']}'.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DELIVERED CODE', style: AppText.label.copyWith(fontSize: 9, color: AppColors.cyan)),
                      const SizedBox(height: 2),
                      SelectableText(
                        '${o['delivered_code']}',
                        style: AppText.bodyStrong.copyWith(color: AppColors.gold, fontSize: 13, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.cyan, size: 18),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${o['delivered_code']}'));
                    HapticFeedback.selectionClick();
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(Fmt.relative('${o['created_at']}'), style: AppText.tiny),
      ]),
    );
  }
}

void _showCodeDialog(BuildContext context, String code) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Text('Code Delivered!', style: AppText.h3),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Your digital voucher / redeem code is ready:'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cyan),
            ),
            child: SelectableText(
              code,
              textAlign: TextAlign.center,
              style: AppText.numM.copyWith(color: AppColors.gold, fontSize: 18, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: BzButton(
            label: 'COPY CODE',
            kind: BzBtn.primary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
            },
          ),
        ),
      ],
    ),
  );
}
