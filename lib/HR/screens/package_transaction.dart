import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../../Services/api_services.dart';
import '../model/service_api_model.dart';
import 'ForceUpdate/Forcelogout.dart';

class PackageFeaturesPage extends StatefulWidget {
  const PackageFeaturesPage({super.key});

  @override
  State<PackageFeaturesPage> createState() => _PackageFeaturesPageState();
}

class _PackageFeaturesPageState extends State<PackageFeaturesPage> {
  late Future<List<PackageFeature>> _future;
  bool _summaryOpen = true;

  @override
  void initState() {
    super.initState();
    _future = HrProfile.fetchCurrentPackageFeatures();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = HrProfile.fetchCurrentPackageFeatures();
      _summaryOpen = false;
    });
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('My Package', style: TextStyle(color: Color(0xFF003840))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF003840)),
      ),
      backgroundColor: const Color(0xffe5ebeb),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<PackageFeature>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _PackageFeaturesSkeleton();
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


            final items = snap.data ?? const <PackageFeature>[];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.card_membership_rounded,
                          size: 48, color: Color(0xFF003840)),
                      SizedBox(height: 8),
                      Text(
                        "No active package",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003840),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Your package features will appear here.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Use first item just to show plan name & validity
            final plan = items.first.packageName;
            final end = items.first.endDate;

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _summaryCard(
                  planName: plan.isEmpty ? 'Current Plan' : plan,
                  validityText: end != null ? 'Valid till ${_fmtDate(end)}' : '',
                  isOpen: _summaryOpen,
                  onToggle: () => setState(() => _summaryOpen = !_summaryOpen),
                ),
                const SizedBox(height: 8),

                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _detailsTable(items),
                  crossFadeState: _summaryOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Summary with Show/Hide toggle
  Widget _summaryCard({
    required String planName,
    required String validityText,
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
              child: const Icon(Icons.workspace_premium_outlined,
                  color: Color(0xFF003840)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planName,
                      style: const TextStyle(
                          color: Color(0xFF003840),
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  if (validityText.isNotEmpty)
                    Text(validityText,
                        style: const TextStyle(color: Color(0xFF003840))),
                ],
              ),
            ),
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  /// Details table like your screenshot
  Widget _detailsTable(List<PackageFeature> items) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tableHeader(),
            const Divider(height: 16),
            ...items.map(_tableRow),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'Feature Name',
            style: TextStyle(
              color: Color(0xFF003840),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Allowed\nQuantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF003840),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Used\nQuantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF003840),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableRow(PackageFeature f) {
    final Widget allowed = f.isIncludedFeature
        ? _checkIcon()
        : Text('${f.totalNumber}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF003840)));

    final Widget used = f.isIncludedFeature
        ? _checkIcon()
        : Text('${f.usedNumber}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF003840)));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              f.moduleName,
              style: const TextStyle(
                color: Color(0xFF003840),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: allowed),
          Expanded(child: used),
        ],
      ),
    );
  }

  Widget _checkIcon() {
    return const Icon(Icons.check_circle, color: Color(0xFF0F9D58), size: 20);
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

/// 🔹 SKELETONIZER UI for "My Package"
class _PackageFeaturesSkeleton extends StatelessWidget {
  const _PackageFeaturesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          // Summary skeleton (same layout as _summaryCard)
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      Icons.workspace_premium_outlined,
                      color: Color(0xFF003840),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Plan',
                          style: TextStyle(
                            color: Color(0xFF003840),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Valid till 01 Jan 2025',
                          style: TextStyle(
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
                      // color: const Color(0xff005E6A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Hide Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_up_rounded,
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

          // Details card skeleton
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Feature Name',
                          style: TextStyle(
                            color: Color(0xFF003840),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Allowed\nQuantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF003840),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Used\nQuantity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF003840),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 16),

                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),
                  _PackageRowSkeleton(),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageRowSkeleton extends StatelessWidget {
  const _PackageRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              'Feature Name Placeholder',
              style: TextStyle(
                color: Color(0xFF003840),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '10',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF003840)),
            ),
          ),
          Expanded(
            child: Text(
              '2',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF003840)),
            ),
          ),
        ],
      ),
    );
  }
}
