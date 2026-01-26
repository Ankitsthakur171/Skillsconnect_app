import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../bloc/Summary/summary_bloc.dart';
import '../bloc/Summary/summary_event.dart';
import '../bloc/Summary/summary_state.dart';
import '../widgets/summary_card.dart';
import '../model/summary_card_model.dart';
import 'ForceUpdate/Forcelogout.dart';

// ✅ import Oops page & failure


class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SummaryBloc()..add(LoadSummary()), // job_id changed here
      child: Scaffold(
        body: BlocBuilder<SummaryBloc, SummaryState>(
          builder: (context, state) {
            if (state is SummaryLoaded) {
              final List<SummaryCardModel> summaryData = [
                SummaryCardModel(
                  title: 'Applications',
                  value: state.applications.toString(),
                  imageAsset: 'assets/applications.png',
                ),
                SummaryCardModel(
                  title: 'Invited',
                  value: state.invited.toString(),
                  imageAsset: 'assets/invited.png',
                ),
                SummaryCardModel(
                  title: 'Selected Candidate',
                  value: state.selected.toString(),
                  imageAsset: 'assets/selected.png',
                ),
                SummaryCardModel(
                  title: 'Rejected Candidate',
                  value: state.rejected.toString().padLeft(2, '0'),
                  imageAsset: 'assets/rejected.png',
                ),
              ];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: summaryData.map((e) => SummaryCard(data: e)).toList(),
              );
            }

            else if (state is SummaryError) {

              print('🟠 Summary Error Occurred!');
              print('🔹 Status Code: ${state.statusCode}');
              print('🔹 Message: ${state.message}');

              int? extractedCode;
              if (state.statusCode == null && state.message != null) {
                final match = RegExp(r'\b(\d{3})\b').firstMatch(state.message!);
                if (match != null) {
                  extractedCode = int.tryParse(match.group(1)!);
                  print('🧩 Extracted Status Code from message: $extractedCode');
                }
              }

              final actualCode = state.statusCode ?? extractedCode;
              print('✅ Final Status Code Used: $actualCode');
              // 🔴 NEW: 401 → force logout
              if (actualCode == 401) {
                ForceLogout.run(context, message: 'You are currently logged in on another device. '
                    'Logging in here will log you out from the other device');
                return const SizedBox.shrink(); // UI placeholder while navigating
              }

              // 🔴 NEW: 403 → force logout
              if (actualCode == 403) {
                ForceLogout.run(context, message: "session expired.");
                return const SizedBox.shrink();
              }
              // 🔹 403 detect hone par direct subscription page
              final isExpired403 = actualCode == 406;

              if (isExpired403) {
                print('⚠️ Subscription expired detected (403)');
                return const SubscriptionExpiredScreen();
              }

              final failure = ApiHttpFailure(
                statusCode: actualCode, // ✅ yahan null mat do, actual code bhejo
                body: state.message, // ✅ body ke jagah message (agar class me message hai)
              );

              return OopsPage(failure: failure);


              // // 🔥 yahan OopsPage dikhao instead of plain text
              // final failure = ApiHttpFailure(
              //   statusCode: 0,       // agar tumhare state me code hai
              //   body: state.message,          // backend se aaya hua error
              // );
              // return OopsPage(failure: failure);
            }

            // ⏳ LOADING / INITIAL – skeletonizer effect
            if (state is SummaryLoading || state is SummaryInitial) {
              // fake data sirf layout ke liye (values matter nahi, skeleton ban jayega)
              final List<SummaryCardModel> dummyData = [
                SummaryCardModel(
                  title: 'Applications',
                  value: '00',
                  imageAsset: 'assets/applications.png',
                ),
                SummaryCardModel(
                  title: 'Invited',
                  value: '00',
                  imageAsset: 'assets/invited.png',
                ),
                SummaryCardModel(
                  title: 'Selected Candidate',
                  value: '00',
                  imageAsset: 'assets/selected.png',
                ),
                SummaryCardModel(
                  title: 'Rejected Candidate',
                  value: '00',
                  imageAsset: 'assets/rejected.png',
                ),
              ];

              return Skeletonizer(
                enabled: true,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: dummyData
                      .map((e) => SummaryCard(data: e))
                      .toList(),
                ),
              );
            }

            // fallback (agar koi aur unknown state ho) – skeleton hi dikha do
            return Skeletonizer(
              enabled: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  // yahan bhi same SummaryCard layout chala sakte the,
                  // but simple placeholder text bhi chalega
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 80),
                  ),
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 80),
                  ),
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 80),
                  ),
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}