// lib/screens/transactions_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../../Services/api_services.dart';
import '../model/service_api_model.dart';
import 'ForceUpdate/Forcelogout.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late Future<List<PaymentTransaction>> _future;

  // 🔹 summary-level expand/collapse
  bool _summaryOpen = true;

  @override
  void initState() {
    super.initState();
    _future = HrProfile.fetchTransactions();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = HrProfile.fetchTransactions();
      _summaryOpen = false;
    });
  }

  String _fmtAmount(int v) {
    final f = NumberFormat.decimalPattern('en_IN');
    return '₹ ${f.format(v)}';
  }

  String _fmtDate(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Color _statusBg(String s) {
    switch (s.toLowerCase()) {
      case 'success':
        return const Color(0xFFCAFEE3);
      case 'pending':
        return const Color(0xFFFFF1C2);
      case 'failed':
      case 'failure':
        return const Color(0xFFFCDDD7);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusText(String s) {
    switch (s.toLowerCase()) {
      case 'success':
        return const Color(0xFF006A41);
      case 'pending':
        return const Color(0xFF6A5D00);
      case 'failed':
      case 'failure':
        return const Color(0xFFB22121);
      default:
        return const Color(0xFF003840);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('My Transactions', style: TextStyle(color: Color(0xFF003840))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF003840)),
      ),
      backgroundColor: const Color(0xffe5ebeb),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PaymentTransaction>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _TransactionsSkeleton();
            }

            if (snap.hasError) {
              print('🟠 Snapshot Error Detected: ${snap.error}');

              ApiHttpFailure failure;

              if (snap.error is ApiHttpFailure) {
                failure = snap.error as ApiHttpFailure;
              } else {
                // 🔹 extract 3-digit code (e.g. 403) from message text
                final msg = snap.error.toString();
                final extracted = _extractStatusCode(msg) ?? 500;

                failure = ApiHttpFailure(
                  statusCode: extracted,
                  body: msg,
                );
              }

              final code = failure.statusCode;
              final message = failure.message?.toLowerCase() ?? '';

              print('🔹 Final Error Code: $code');
              print('🔹 Error Message: $message');

              final isExpired403 = code == 406 || message.contains('expired');

              if (isExpired403) {
                print('⚠️ Subscription expired detected inside FutureBuilder');
                return const SubscriptionExpiredScreen();
              }

              // 🔴 401 → force logout
              if (code == 401) {
                ForceLogout.run(
                  context,
                  message:
                  'You are currently logged in on another device. Logging in here will log you out from the other device.',
                );
                return const SizedBox.shrink();
              }

              // 🔴 403 → force logout
              if (code == 403) {
                ForceLogout.run(
                  context,
                  message: 'Session expired.',
                );
                return const SizedBox.shrink();
              }

              return OopsPage(failure: failure);
            }

            // if (snap.hasError) {
            //   final failure = snap.error is ApiHttpFailure
            //       ? snap.error as ApiHttpFailure
            //       : ApiHttpFailure(
            //     statusCode: 500,
            //     body: snap.error.toString(),
            //   );
            //
            //   return OopsPage(failure: failure);
            // }

            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.receipt_long_rounded,
                          size: 48, color: Color(0xFF003840)),
                      SizedBox(height: 8),
                      Text(
                        "No transactions yet",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003840),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your payments and transactions will appear here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalAmount = items.fold<int>(0, (sum, e) => sum + e.netAmount);

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                // 🔹 summary card with Show/Hide toggle (replaces "N Txns")
                _summaryCard(
                  total: _fmtAmount(totalAmount),
                  count: items.length,
                  isOpen: _summaryOpen,
                  onToggle: () => setState(() => _summaryOpen = !_summaryOpen),
                ),
                const SizedBox(height: 8),

                // 🔻 details panel (no success cards; only compact detail rows)
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _detailsPanel(items),
                  crossFadeState:
                  _summaryOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Summary with toggle button
  Widget _summaryCard({
    required String total,
    required int count,
    required bool isOpen,
    required VoidCallback onToggle,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF6F7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x40003840)),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF003840)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Amount",
                      style: TextStyle(color: Color(0xFF003840))),
                  Text(
                    total,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003840),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Show Details / Hide Details toggle (replaces "N Txns")
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff005E6A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Text(
                      isOpen ? 'Hide Details' : 'Show Details',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact list of details for each transaction (no success card UI)
  Widget _detailsPanel(List<PaymentTransaction> items) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // optional heading row
            Row(
              children: const [
                Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF003840)),
                SizedBox(width: 6),
                Text(
                  'Transaction Details',
                  style: TextStyle(
                    color: Color(0xFF003840),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // each transaction details block
            ...items.asMap().entries.map((e) {
              final t = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF6F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x40003840)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // amount + status chip (small, optional)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _fmtAmount(t.netAmount),
                            style: const TextStyle(
                              color: Color(0xFF003840),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusBg(t.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t.status,
                            style: TextStyle(
                              color: _statusText(t.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _detailRow('Payment Mode', t.paymentMode),
                    const SizedBox(height: 6),
                    _detailRow('Transaction Number', t.transactionId),
                    const SizedBox(height: 6),
                    _detailRow('Transaction Status', t.status),

                    // (optional) date line
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Color(0xFF003840)),
                        const SizedBox(width: 6),
                        Text(
                          _fmtDate(t.createdOn),
                          style: const TextStyle(color: Color(0xFF003840), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // small pill (kept for potential reuse)
  Widget _pill({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffEBF6F7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x40003840)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF003840)),
      ),
    );
  }

  // detail row style
  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF003840),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF003840),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
  int? _extractStatusCode(String? text) {
    if (text == null) return null;
    final match = RegExp(r'\b(\d{3})\b').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

}

class _TransactionsSkeleton extends StatelessWidget {
  const _TransactionsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // 🔹 Summary skeleton
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF6F7),
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: const Color(0x40003840)),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF003840),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(color: Color(0xFF003840)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "₹ 0",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003840),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      // color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Show Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 🔹 Details card skeleton
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // heading row
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF003840),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Transaction Details',
                        style: TextStyle(
                          color: Color(0xFF003840),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3 fake items
                  const _SkeletonTransactionItem(),
                  const _SkeletonTransactionItem(),
                  const _SkeletonTransactionItem(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTransactionItem extends StatelessWidget {
  const _SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEBF6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x40003840)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // amount + status chip
          Row(
            children: [
              const Expanded(
                child: Text(
                  '₹ 0',
                  style: TextStyle(
                    color: Color(0xFF003840),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFCAFEE3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Success',
                  style: TextStyle(
                    color: Color(0xFF006A41),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment Mode
          const _SkeletonDetailRow(
            label: 'Payment Mode',
            value: 'Online',
          ),
          const SizedBox(height: 6),

          // Transaction Number
          const _SkeletonDetailRow(
            label: 'Transaction Number',
            value: 'TXN000000',
          ),
          const SizedBox(height: 6),

          // Transaction Status
          const _SkeletonDetailRow(
            label: 'Transaction Status',
            value: 'Success',
          ),

          const SizedBox(height: 6),

          // Date line
          Row(
            children: const [
              Icon(
                Icons.event,
                size: 16,
                color: Color(0xFF003840),
              ),
              SizedBox(width: 6),
              Text(
                '01 Jan 2025, 10:00 AM',
                style: TextStyle(
                  color: Color(0xFF003840),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _SkeletonDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF003840),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF003840),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
