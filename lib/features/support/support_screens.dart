import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
import '../../core/widgets/gt_shapes.dart';
import '../extras/extras_repository.dart';

Future<String?> _pickImageB64() async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, maxHeight: 1400, imageQuality: 80);
  if (x == null) return null;
  return 'data:image/jpeg;base64,${base64Encode(await x.readAsBytes())}';
}

/// Ticket list + "new ticket"
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ticketsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _newTicket(context, ref, data.valueOrNull),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text('NEW TICKET', style: AppText.button),
      ),
      body: BzBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(ticketsProvider),
          child: data.when(
            loading: () => const BzSkeletonList(itemHeight: 80, count: 4),
            error: (e, _) => ListView(children: [BzError(message: '$e', onRetry: () => ref.invalidate(ticketsProvider))]),
            data: (d) {
              final list = (d['tickets'] as List).cast<Map>();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  GtCutCard(
                    gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: .22), AppColors.card]),
                    child: Row(children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.primaryHi, size: 34),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('We are here to help', style: AppText.bodyStrong),
                        Text('Support hours: ${d['support_hours'] ?? ''}', style: AppText.bodyS),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  if (list.isEmpty)
                    const BzEmpty(title: 'No tickets yet', message: 'Tap NEW TICKET if you have a problem with a match, deposit, withdraw or order.', icon: Icons.forum_rounded)
                  else ...[
                    const GtSectionTitle('Your tickets'),
                    for (var i = 0; i < list.length; i++)
                      GtCutCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        onTap: () => context.push('/support/${list[i]['id']}'),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${list[i]['subject']}', style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text('${list[i]['category']}  ·  ${list[i]['last_body'] ?? ''}', style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(Fmt.relative('${list[i]['last_message_at']}'), style: AppText.tiny),
                          ])),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            StatusPill('${list[i]['status']}'.toUpperCase(), color: list[i]['status'] == 'open' ? AppColors.success : AppColors.textMuted),
                            if ((list[i]['unread'] as num) > 0) ...[
                              const SizedBox(height: 6),
                              CircleAvatar(radius: 10, backgroundColor: AppColors.primary,
                                  child: Text('${list[i]['unread']}', style: AppText.tiny.copyWith(color: Colors.white))),
                            ],
                          ]),
                        ]),
                      ).stagger(i),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _newTicket(BuildContext context, WidgetRef ref, Map<String, dynamic>? d) {
    final cats = ((d?['categories'] as List?) ?? const ['Match', 'Deposit', 'Withdraw', 'Shop', 'Account', 'Other']).cast<String>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NewTicketSheet(categories: cats),
    );
  }
}

class _NewTicketSheet extends ConsumerStatefulWidget {
  const _NewTicketSheet({required this.categories});
  final List<String> categories;
  @override
  ConsumerState<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends ConsumerState<_NewTicketSheet> {
  final _subject = TextEditingController();
  final _msg = TextEditingController();
  late String _cat = widget.categories.first;
  String? _img;
  bool _busy = false;

  Future<void> _send() async {
    if (_subject.text.trim().length < 3 || _msg.text.trim().length < 2) {
      showSnack(context, 'Write a subject and your message.', kind: SnackKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref.read(extrasRepoProvider).newTicket(subject: _subject.text.trim(), category: _cat, message: _msg.text.trim(), imageB64: _img);
      ref.read(extrasRefreshProvider.notifier).state++;
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/support/${(r['ticket'] as Map)['id']}');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('New support ticket', style: AppText.h3),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in widget.categories)
              ChoiceChip(
                label: Text(c),
                selected: _cat == c,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                labelStyle: AppText.bodyStrong.copyWith(fontSize: 12.5, color: _cat == c ? Colors.white : AppColors.textDim),
                onSelected: (_) => setState(() => _cat = c),
              ),
          ]),
          const SizedBox(height: 14),
          BzField(controller: _subject, label: 'SUBJECT', hint: 'e.g. Deposit not added', icon: Icons.title_rounded, maxLength: 120),
          const SizedBox(height: 8),
          BzField(controller: _msg, label: 'MESSAGE', hint: 'Explain the problem (TrxID, match name…)', icon: Icons.chat_rounded),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final b = await _pickImageB64();
              if (b != null) setState(() => _img = b);
            },
            icon: Icon(_img == null ? Icons.image_rounded : Icons.check_circle_rounded, color: _img == null ? AppColors.textDim : AppColors.success),
            label: Text(_img == null ? 'Attach screenshot (optional)' : 'Screenshot attached'),
          ),
          const SizedBox(height: 14),
          BzButton(label: 'SUBMIT', icon: Icons.send_rounded, loading: _busy, onPressed: _busy ? null : _send),
        ]),
      ),
    );
  }
}

/// Chat view for one ticket
class TicketChatScreen extends ConsumerStatefulWidget {
  const TicketChatScreen({super.key, required this.id});
  final int id;
  @override
  ConsumerState<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends ConsumerState<TicketChatScreen> {
  final _msg = TextEditingController();
  bool _busy = false;

  Future<void> _send({String? img}) async {
    final text = _msg.text.trim();
    if (text.isEmpty && img == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(extrasRepoProvider).reply(widget.id, body: text, imageB64: img);
      _msg.clear();
      ref.invalidate(ticketProvider(widget.id));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ticketProvider(widget.id));
    final t = data.valueOrNull?['ticket'] as Map?;
    final closed = t?['status'] == 'closed';
    return Scaffold(
      appBar: AppBar(
        title: Text(t?['subject'] ?? 'Ticket', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (t != null && !closed)
            TextButton(
              onPressed: () async {
                await ref.read(extrasRepoProvider).closeTicket(widget.id);
                ref.read(extrasRefreshProvider.notifier).state++;
              },
              child: Text('CLOSE', style: AppText.label.copyWith(color: AppColors.textDim)),
            ),
        ],
      ),
      body: BzBackground(
        child: Column(children: [
          Expanded(
            child: data.when(
              loading: () => const BzLoader(),
              error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(ticketProvider(widget.id))),
              data: (d) {
                final msgs = (d['messages'] as List).cast<Map>();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(ticketProvider(widget.id)),
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => _Bubble(m: msgs[msgs.length - 1 - i].cast<String, dynamic>()),
                  ),
                );
              },
            ),
          ),
          if (closed)
            Padding(padding: const EdgeInsets.all(16), child: Text('This ticket is closed. Open a new one if you need more help.', style: AppText.bodyS, textAlign: TextAlign.center))
          else
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: const BoxDecoration(color: AppColors.bg2, border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.image_rounded, color: AppColors.textDim),
                    onPressed: _busy ? null : () async {
                      final b = await _pickImageB64();
                      if (b != null) _send(img: b);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msg,
                      minLines: 1, maxLines: 4,
                      style: AppText.bodyM.copyWith(color: AppColors.text),
                      decoration: const InputDecoration(hintText: 'Write a message…', border: InputBorder.none, isDense: true),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _busy ? null : () => _send(),
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m});
  final Map<String, dynamic> m;
  @override
  Widget build(BuildContext context) {
    final mine = m['from'] == 'user';
    final img = m['image_url'] as String?;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary.withValues(alpha: .9) : AppColors.cardHi,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4), bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!mine) Text('Support', style: AppText.label.copyWith(color: AppColors.gold, fontSize: 10)),
          if (img != null && img.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: img)),
            ),
          if ('${m['body']}'.isNotEmpty) Text('${m['body']}', style: AppText.bodyM.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(Fmt.relative('${m['created_at']}'), style: AppText.tiny.copyWith(color: Colors.white60)),
        ]),
      ),
    );
  }
}

/// Simple centred button used where BzButton would be too wide.
class SupportShortcut extends StatelessWidget {
  const SupportShortcut({super.key});
  @override
  Widget build(BuildContext context) =>
      BzButton(label: 'CONTACT SUPPORT', icon: Icons.support_agent_rounded, kind: BzBtn.ghost, onPressed: () => context.push('/support'));
}
