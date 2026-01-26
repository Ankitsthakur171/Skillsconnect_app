// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class TermsConditionsPage extends StatelessWidget {
//   const TermsConditionsPage({super.key});
//
//   static const Color _titleColor = Color(0xFF003840);
//   static const Color _accent = Color(0xFF005E6A);
//   static const Color _bg = Colors.white;
//   static const double _bodyFontSize = 14;
//
//   Text _h1(String text) => Text(
//     text,
//     style: TextStyle(
//       color: _titleColor,
//       fontSize: 18.sp,
//       fontWeight: FontWeight.w700,
//     ),
//   );
//
//   Text _h2(String text) => Text(
//     text,
//     style: TextStyle(
//       color: _titleColor,
//       fontSize: 15.sp,
//       fontWeight: FontWeight.w700,
//     ),
//   );
//
//   Widget _p(String text) => Padding(
//     padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
//     child: Text(
//       text,
//       style: TextStyle(
//         color: const Color(0xFF22383A),
//         fontSize: _bodyFontSize.sp,
//         height: 1.5,
//       ),
//     ),
//   );
//
//   Widget _numberedNotes(List<String> notes) => Padding(
//     padding: EdgeInsets.only(top: 6.h, bottom: 6.h),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: List.generate(
//         notes.length,
//             (i) => Padding(
//           padding: EdgeInsets.symmetric(vertical: 4.h),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '${i + 1}. ',
//                 style: TextStyle(
//                   color: const Color(0xFF22383A),
//                   fontSize: _bodyFontSize.sp,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Expanded(
//                 child: Text(
//                   notes[i],
//                   style: TextStyle(
//                     color: const Color(0xFF22383A),
//                     fontSize: _bodyFontSize.sp,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     ScreenUtil.init(
//       context,
//       designSize: const Size(390, 844),
//       minTextAdapt: true,
//       splitScreenMode: true,
//     );
//
//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: AppBar(
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: _titleColor, size: 24.w),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: Text(
//           'Terms & Conditions',
//           style: TextStyle(
//             color: _titleColor,
//             fontWeight: FontWeight.w600,
//             fontSize: 18.sp,
//           ),
//         ),
//
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: EdgeInsets.all(14.w),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF0F7F7),
//                   borderRadius: BorderRadius.circular(12.r),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Welcome to SkillsConnect!',
//                       style: TextStyle(
//                           color: _titleColor,
//                           fontWeight: FontWeight.w700,
//                           fontSize: 16.sp),
//                     ),
//                     SizedBox(height: 8.h),
//                     Text(
//                       'We are a career services platform that connects students and employers to democratize the job finding experience in college and beyond.',
//                       style: TextStyle(
//                         color: const Color(0xFF22383A),
//                         fontSize: _bodyFontSize.sp,
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16.h),
//
//               _h2('Terms of Service'),
//               _p(
//                   'This Terms of Service applies to your use of the SkillsConnect.in website and the Accura Solutions Ltd. (collectively referred as “SkillsConnect” or “SkillsConnect.in” or “the SkillsConnect Service” or “the Service”), as well as your relationship with Acura Solutions Ltd. and Skillsconnect.in.'),
//               _p('If you do not agree with these Terms, please discontinue using the Service.'),
//               _p(
//                   'These Terms will change over time. If we make minor changes to the Terms without materially changing your rights, we will post the modified Terms on our website. We may notify you by email, through the SkillsConnect Service, or by presenting you with a new Terms of Service to accept if we make a modification that materially changes your rights. When you use the SkillsConnect Service after a modification is posted, you are telling us that you accept the modified terms.'),
//
//               _h2('Account Creation'),
//               _p(
//                   'You need to have an account to use SkillsConnect. You can create an account on SkillsConnect as a student seeking a job or career advice, as an employer looking for exciting new talent, or as a career center professional associated with an academic institution. You agree not to misrepresent any information about yourself in creating or using an account.'),
//
//               _h2('Creating an Employer Account'),
//               _p(
//                   'When you create a SkillsConnect Employer Account, we request contact information, including email address and telephone number, to provide a point of contact for Universities and administrative staff. We will not use your phone number to send any commercial or marketing messages to you from third parties. You agree to provide accurate and current information and to correct any misrepresentations immediately upon discovery. You agree that SkillsConnect may use your contact information to directly contact you to market additional offerings on SkillsConnect.'),
//
//               _p(
//                   'SkillsConnect may show you listings of all/other University Partners and you can recruit students from these listed University Partners.'),
//
//               _p(
//                   'By creating an account on SkillsConnect, all universities will have access to information used to create the account. Once your account has been approved by participating Universities, you will receive student data through our Service. You are prohibited from disclosing or sharing this information with other parties, and agree to keep student data confidential. You agree to handle and maintain collected student data with equivalent or superior standards, including the requirements of the local laws regarding any Student Personal Data you receive from SkillsConnect. You also agree not to use the Service to send spam or other unauthorized communications, and you agree not to use any collected student data for purposes not authorized by SkillsConnect.'),
//
//               _h2('Employer Account Guidelines'),
//               _p(
//                   'Through the use of the Service, you will be able to search and filter student results based on a wide range of criteria. You agree to maintain a fair and equitable recruitment process when selecting student candidates. You also agree not to discriminate based on ethnicity, national origin, religion, age, gender, sexual orientation, disability, or veteran status as prohibited by law. You have the ability to contact students directly through the Service. By using this Service, you agree not to stalk, defame, bully, harass, abuse, threaten, intimidate, or impersonate any people or entities.'),
//
//               _p(
//                   'Employer Accounts are administered by designated Account Administrators. If the employer chooses to allow additional individual employees to access the SkillsConnect Service through the Employer Account, you agree that the account administrators are responsible for the use of the Service by those individual employees, including requests related to personal data collected from those individual employees. You acknowledge and agree that SkillsConnect is not responsible for the privacy or security practices of an administrator\'s organization.'),
//
//               _h2('Third Party Recruiter Guidelines'),
//               _p(
//                   'SkillsConnect is excited to offer as many career opportunities to students as possible, including those offered by third party recruiters. However, we do not permit outside services from bulk collecting student data, employer data, job descriptions, or other marketplace information through the use of automated scripts (“scraping”) or similar technologies or methodologies. Third party recruiters are also prohibited from requiring students to create an account on a third-party platform unaffiliated with the company or brand providing the employment role. Any violation of these, or any other Terms, at our discretion, may result in suspension or termination of the account(s) associated with you or your recruitment service.'),
//
//               _h2('General Guidelines'),
//               _p(
//                   'SkillsConnect does not claim ownership of any Content that you post on or through the Service. By making Your Content available on or through the Service you grant to SkillsConnect a non-exclusive, transferable, sublicensable, worldwide, royalty-free license to use, copy, modify, publicly display, publicly perform and distribute Your Content only in connection with operating and providing the SkillsConnect Service.'),
//
//               _p(
//                   'You are responsible for Your Content. You represent and warrant that you own Your Content or that you have all rights necessary to grant us a license to use Your Content as described in these Terms. You also represent and warrant that Your Content and the use and provision of Your Content on the SkillsConnect Service will not: (a) infringe, misappropriate or violate a third party’s patent, copyright, trademark, trade secret, moral rights or other intellectual property rights, or rights of publicity or privacy; (b) violate, or encourage any conduct that would violate, any applicable law or regulation or would give rise to civil liability; (c) be fraudulent, false, misleading or deceptive; (d) be defamatory, obscene, pornographic, vulgar or offensive; (e) promote discrimination, bigotry, racism, hatred, harassment or harm against any individual or group; (f) be violent or threatening or promote violence or actions that are threatening to any person or entity; or (g) promote illegal or harmful activities or substances.'),
//
//               _h2('Our Intellectual Property Belongs to Us'),
//               _p(
//                   'SkillsConnect Content is protected by copyright, trademark, patent, trade secret and other laws, and, as between you and SkillsConnect, we own and retain all rights to the SkillsConnect Content and the Service. You will not remove, alter or conceal any copyright, trademark, service mark or other proprietary rights notices incorporated in or accompanying the SkillsConnect Content and you will not reproduce, modify, adapt, prepare derivative works based on, perform, display, publish, distribute, transmit, broadcast, sell, license or otherwise exploit our Content.'),
//
//               _h2('Termination'),
//               _p('We reserve the right to suspend or terminate your account(s) for violation of these Terms of Service or any other policies associated with the Services.'),
//
//               _h2('Account and Website Security'),
//               _p(
//                   'While we take steps to protect your data from unauthorized access, security is a team effort. You are responsible for keeping your password secret and secure, and we encourage you to update your password regularly.'),
//
//               _h2('No Monitoring'),
//               _p(
//                   'You are solely responsible for your interaction with other users of the Service, whether online or offline. You agree that we are not responsible or liable for your conduct. We reserve the right, but have no obligation, to monitor or become involved in disputes between you and other users. Exercise common sense and your best judgment when interacting with others, including when you submit or post Content or any personal or other information.'),
//
//               _h2('Third Party Links'),
//               _p(
//                   'Our Service contains links to third-party websites, apps, services and resources (collectively “Third-Party Services”) that are not under SkillsConnect’s control. We provide these links only as a convenience and are not responsible for the content, products or services that are available from Third-Party Services. You acknowledge sole responsibility and assume all risk arising from your use of any Third-Party Services.'),
//
//               _h2('Violation and Enforcement of These Terms'),
//               _p(
//                   'We reserve the right to refuse access to the Service to anyone for any reason at any time. We reserve the right to force forfeiture of any username or account for any reason. We may, but have no obligation to, remove, edit, block, and/or monitor Content or accounts containing Content that we determine in our sole discretion violates these Terms of Service.'),
//
//               _h2('Controlling Terms'),
//               _p(
//                   'SkillsConnect is continually improving its Service, and we may occasionally offer special features or functionality which include additional Terms of Service. If any of the additional Terms conflict with the Terms described below, the additional Terms control.'),
//
//               _h2('Reporting Copyright and Other IP Violations'),
//               _p(
//                   'We respect other people’s rights, and expect you to do the same. If you repeatedly infringe other people’s intellectual property rights, we will disable your account when appropriate.'),
//
//               _h2('Disclaimer of Warranties'),
//               _p(
//                   'The service, including, without limitation, SkillsConnect content, is provided on an “as is”, “as available” and “with all faults” basis. To the fullest extent permissible by law, neither SkillsConnect nor any of its employees, partners, managers, officers or agents (collectively, the “SkillsConnect parties”) make any representations or warranties or endorsements of any kind whatsoever, express or implied.'),
//
//               _h2('Limitation of Liability; Waiver'),
//               _p(
//                   'Under no circumstances will the SkillsConnect parties be liable to you for any loss or damages of any kind (including, without limitation, for any direct, indirect, economic, exemplary, special, punitive, incidental or consequential losses or damages) that are directly or indirectly related to: (a) the service; (b) the SkillsConnect content; (c) user content; (d) your use of, inability to use, or the performance of the service; ...'), // truncated in preview; full text follows
//
//               // continue large paragraph example (use full text in actual app)
//               _p(
//                   'You agree that in the event you incur any damages, losses or injuries that arise out of SkillsConnect’s acts or omissions, the damages, if any, caused to you are not irreparable or sufficient to entitle you to an injunction preventing any exploitation of any web site, service, property, product or other content owned or controlled by the SkillsConnect parties, and you will have no rights to enjoin or restrain the development, production, distribution, advertising, exhibition or exploitation of any web site, property, product, service, or other content owned or controlled by the SkillsConnect parties.'),
//
//               _h2('Indemnification'),
//               _p(
//                   'Unless prohibited by law, You (and also any third party for whom you operate an account or activity on the Service) agree to defend (at SkillsConnect’s request), indemnify and hold the SkillsConnect Parties harmless from and against any claims, liabilities, damages, losses, and expenses...'),
//
//               _h2('Entire Agreement'),
//               _p(
//                   'If you are using the Service on behalf of a legal entity, you represent that you are authorized to enter into an agreement on behalf of that legal entity. These Terms of Service constitute the entire agreement between you and SkillsConnect and governs your use of the Service, unless you have a separate signed agreement with SkillsConnect that states it supersedes this Terms of Service.'),
//
//               _h2('Consent to Process Personal Data'),
//               _p(
//                   'By clicking the link, you explicitly consent to the collection, processing, and storage of your personal data by SkillsConnect as described in our Privacy Policy. We collect personal data for the purposes of providing and improving our services, communicating with you, and meeting our legal obligations.'),
//
//               _h2('Note'),
//               _numberedNotes([
//                 'We do not identify tiering of colleges. It is clients discretion',
//                 'We do not ensure application mobilization. It depends on CTC offered by client, profile, academic calendar and various other factors.',
//                 'No free replacement',
//                 '100% payment advance to be made for SaaS model',
//                 '18% GST applicable additional on the package cost',
//                 'Any third-party tool charges are not included in the packages mentioned above',
//                 'Any customization in the process flow will be charged additionally',
//                 'Selection of candidates should be updated on the skillsconnect platform on timely basis.',
//               ]),
//
//               _p(
//                   'This Agreement shall be governed by the laws of India. In respect of all matters arising out or relating to this Agreement, the courts at Mumbai, India shall have exclusive jurisdiction.'),
//
//               SizedBox(height: 24.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//do not delete//

// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class TermsConditionsWebView extends StatefulWidget {
//   const TermsConditionsWebView({super.key});
//
//   @override
//   State<TermsConditionsWebView> createState() => _TermsConditionsWebViewState();
// }
//
// class _TermsConditionsWebViewState extends State<TermsConditionsWebView> {
//   late final WebViewController _controller;
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xFFFFFFFF))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (_) => setState(() => _loading = true),
//           onPageFinished: (_) => setState(() => _loading = false),
//         ),
//       )
//       ..loadRequest(Uri.parse('https://skillsconnect.in/terms-conditions'));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Terms & Conditions',
//           style: TextStyle(color: Color(0xFF003840), fontWeight: FontWeight.w700),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         iconTheme: const IconThemeData(color: Color(0xFF003840)),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_loading)
//             const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
//
