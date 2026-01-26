import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:skillsconnect/TPO/Summary/tpo_summary_block.dart';
import 'package:skillsconnect/TPO/Summary/tpo_summary_event.dart';
import 'package:skillsconnect/TPO/Summary/tpo_summary_state.dart';

import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../HR/screens/ForceUpdate/Forcelogout.dart';
import '../Model/tpo_summary.dart';


class SummaryTpoScreen extends StatelessWidget {
  const SummaryTpoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SummaryBloc()..add(LoadSummary()),
      child: Scaffold(
        body: BlocBuilder<SummaryBloc, SummaryState>(
          builder: (context, state) {
            if (state is SummaryLoaded) {
              final List<SummaryCardModel> summaryData = [
                SummaryCardModel(
                  title: 'Jobs',
                  value: state.jobs.toString(),
                  imageAsset: 'assets/applications.png',
                ),
                SummaryCardModel(
                  title: 'Selected Candidates',
                  value: state.selected_candidates.toString(),
                  imageAsset: 'assets/invited.png',
                ),
                SummaryCardModel(
                  title: 'Total Registered Users ',
                  value: state.registered_users.toString(),
                  imageAsset: 'assets/selected.png',
                ),
              ];

              return ListView(
                children: summaryData.map((e) => SummaryCard(data: e)).toList(),
              );
            }
            else if (state is SummaryError) {
              print("❌ SummaryError: ${state.message}");

              int? actualCode;

              // 🔹 Try extracting status code (agar available ho)
              if (state.message != null) {
                final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message!);
                if (match != null) {
                  actualCode = int.tryParse(match.group(1)!);
                }
              }

              // 🔴 401 → force logout (multiple login)
              if (actualCode == 401) {
                ForceLogout.run(
                  context,
                  message: 'You are currently logged in on another device. '
                      'Logging in here will log you out from the other device.',
                );
                return const SizedBox.shrink(); // UI render mat karo
              }

              // 🔴 403 → force logout (session expired)
              if (actualCode == 403) {
                ForceLogout.run(
                  context,
                  message: 'Session expired.',
                );
                return const SizedBox.shrink();
              }
              // 🔥 yahan OopsPage dikhao instead of plain text
              final failure = ApiHttpFailure(
                statusCode: actualCode ?? 0,
                body: state.message,          // backend se aaya hua error
              );
              return OopsPage(failure: failure);
            }

            return const _TpoSummarySkeleton();
          },
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final SummaryCardModel data;
  const SummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Color(0xffe5ebeb),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(data.imageAsset, height: 75, width: 75),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003840),
                  ),
                ),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF003840),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


/// 🔹 Skeleton loader for TPO Summary
class _TpoSummarySkeleton extends StatelessWidget {
  const _TpoSummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // dummy data sirf layout ke liye – Skeletonizer text ko grey blocks bana dega
    final List<SummaryCardModel> dummyData = [
      SummaryCardModel(
        title: 'Jobs',
        value: '00',
        imageAsset: 'assets/applications.png',
      ),
      SummaryCardModel(
        title: 'Selected Candidates',
        value: '00',
        imageAsset: 'assets/invited.png',
      ),
      SummaryCardModel(
        title: 'Total Registered Users ',
        value: '00',
        imageAsset: 'assets/selected.png',
      ),
    ];

    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: dummyData
            .map((e) => SummaryCard(data: e))
            .toList(),
      ),
    );
  }
}