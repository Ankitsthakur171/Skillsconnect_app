import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../Constant/constants.dart';
import '../../Error_Handler/app_error.dart';
import '../../Error_Handler/oops_screen.dart';
import '../../Error_Handler/subscription_expired_screen.dart';
import '../../Services/api_services.dart';
import '../../utils/company_info_manager.dart';
import '../model/service_api_model.dart';
import 'EnterOtpScreen.dart';
import 'ForceUpdate/Forcelogout.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  // Controllers
  final _companyNameCtrl = TextEditingController();
  final _executiveNameCtrl = TextEditingController();
  final _executiveEmailCtrl = TextEditingController();
  final _executiveMobileCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _companyProfileCtrl = TextEditingController();

  // State
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  List<StateItem> _states = [];
  int? _selectedStateId;

  // City list + selection
  List<_CityItem> _cities = [];
  bool _citySearching = false;
  int? _selectedCityId;
  String? _selectedCityName; // display name

  String _logoPathOrUrl = ''; // preview only

  // ---- Validation flags (for red errorText) ----
  bool _errCompanyName = false;
  bool _errExecutiveName = false;
  bool _errExecutiveEmail = false;
  bool _errWebsite = false;
  bool _errSize = false;
  bool _errAddress = false;
  bool _errPincode = false;
  bool _errState = false;
  bool _errCity = false;

  // 👇 401/403 ko handle karne ke liye tiny helpers
  void _forceLogoutByCode(int? code, {String? reason}) {
    if (!mounted) return;
    if (code == 401) {
      ForceLogout.run(
        context,
        message:
        'You are currently logged in on another device. Logging in here will log you out from the other device',
      );
    } else if (code == 403) {
      ForceLogout.run(context, message: 'session expired.');
    }
  }

  void _forceLogoutFromResponse(http.Response resp, {String? reason}) {
    _forceLogoutByCode(resp.statusCode, reason: reason);
  }


  // 403/406 nikalne ke liye
  int? _extractStatusCodeFromText(String? message) {
    if (message == null) return null;
    final m = RegExp(r'\b(\d{3})\b').firstMatch(message);
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  // ✅ Only 406 (no 403, no keyword fallback)
  bool _looksLikeSubscriptionExpired({int? code, String? body}) {
    final c = code ?? _extractStatusCodeFromText(body);
    return c == 406;
  }

  void _openSubscriptionPageAndStop() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SubscriptionExpiredScreen()),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCompanyDetail();
  }

  Future<void> _loadCompanyDetail() async {
    debugPrint("🚀 Starting _loadCompanyDetail()...");

    try {
      debugPrint("📡 Fetching company details from API...");
      final resp = await HrProfile.fetchCompanyDetail();

      debugPrint("✅ API call success.");
      debugPrint("🏢 companyDetails count: ${resp.companyDetails.length}");
      debugPrint("🌐 states count: ${resp.states.length}");

      final company = resp.companyDetails.isNotEmpty
          ? resp.companyDetails.first
          : null;
      _states = resp.states;

      if (company != null) {
        debugPrint("📋 Prefilling company data...");
        debugPrint("🏭 Company Name: ${company.companyName}");
        debugPrint("👤 Executive Name: ${company.executiveName}");
        debugPrint("📧 Email: ${company.email}");
        debugPrint("📱 Mobile: ${company.mobile}");
        debugPrint("🌍 Website: ${company.website}");
        debugPrint("🏢 Size: ${company.companySize}");
        debugPrint("📍 Address: ${company.address}");
        debugPrint("📮 Pincode: ${company.pincode}");
        debugPrint("📝 Profile: ${company.companyProfile}");
        debugPrint("🗺️ State ID: ${company.stateId}");
        debugPrint("🏙️ City ID: ${company.cityId}");
        debugPrint("🖼️ Logo URL/Path: ${company.companyLogo}");

        // Prefill controllers
        _companyNameCtrl.text = company.companyName ?? '';
        _executiveNameCtrl.text = company.executiveName ?? '';
        _executiveEmailCtrl.text = company.email ?? '';
        _executiveMobileCtrl.text = company.mobile ?? '';
        _websiteCtrl.text = company.website ?? '';
        _sizeCtrl.text = company.companySize ?? '';
        _addressCtrl.text = company.address ?? '';
        _pincodeCtrl.text = company.pincode ?? '';
        _companyProfileCtrl.text = company.companyProfile ?? '';
        _selectedStateId = company.stateId;
        _selectedCityId = company.cityId;
        _logoPathOrUrl = company.companyLogo ?? '';

        // Try to resolve city name from id (once at load)
        if (_selectedCityId != null) {
          debugPrint(
            "🔎 Checking cached city name for ID: ${_selectedCityId!}",
          );
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('city_name_${_selectedCityId!}');
          if (cached != null && cached.isNotEmpty) {
            _selectedCityName = cached;
            debugPrint("⚡ Cached city name found: $_selectedCityName");
          } else {
            debugPrint("🔄 Cache miss, resolving from API...");
            await _resolveCityNameForId(_selectedCityId!, _selectedStateId);
          }
        } else {
          debugPrint("⚠️ No city ID found in company data.");
        }
      } else {
        debugPrint("⚠️ No company data found in response.");
      }

      setState(() {
        _loading = false;
        _error = null;
      });

      debugPrint("✅ _loadCompanyDetail() completed successfully.");
    } catch (e, stack) {
      debugPrint("❌ Error in _loadCompanyDetail(): $e");
      debugPrint("📚 Stack Trace:\n$stack");
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _executiveNameCtrl.dispose();
    _executiveEmailCtrl.dispose();
    _executiveMobileCtrl.dispose();
    _websiteCtrl.dispose();
    _sizeCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
    _companyProfileCtrl.dispose();
    super.dispose();
  }

  ImageProvider _imageProviderFrom(String pathOrUrl) {
    if (pathOrUrl.isEmpty)
      return const AssetImage('assets/company_placeholder.png');
    if (pathOrUrl.startsWith('http')) return NetworkImage(pathOrUrl);
    final f = File(pathOrUrl);
    if (f.existsSync()) return FileImage(f);
    return const AssetImage('assets/company_placeholder.png');
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await HrProfile.submitCompanyProfile(
      companyProfile: _companyProfileCtrl.text.trim(),
      companyName: _companyNameCtrl.text.trim(),
      executiveName: _executiveNameCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      size: _sizeCtrl.text.trim(),
      companyAddress: _addressCtrl.text.trim(),
      stateId: _selectedStateId!.toString(),
      cityId: _selectedCityId!.toString(),
      pincode: _pincodeCtrl.text.trim(),
      executiveEmail: _executiveEmailCtrl.text.trim(),
      executiveMobile: _executiveMobileCtrl.text.trim(),
    );

    setState(() => _submitting = false);

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(result.message.isNotEmpty ? result.message : (result.ok ? 'Updated' : 'Failed')),
    //     backgroundColor: result.ok ? Colors.green : Colors.red,
    //   ),
    // );
    showSuccessSnackBar(
      context,
      result.message.isNotEmpty
          ? result.message
          : (result.ok ? 'Updated' : 'Failed'),
    );

    if (result.ok) {
      // ✅ AppBar ko turant refresh karne ke liye manager update karo
      final prefs = await SharedPreferences.getInstance();
      final currentLogo =
          prefs.getString('company_logo') ?? ''; // jo latest logo URL store hai
      await CompanyInfoManager().setCompanyData(
        _companyNameCtrl.text.trim(), // NEW name
        currentLogo, // logo same rehne do
      );

      _loadCompanyDetail(); // refresh
      // ⬇️ ADD THIS: redirect to Account
      Navigator.pop(context);
    }
  }

  // ---------- City helpers ----------
  Future<void> _searchCities(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _cities = []);
      return;
    }

    setState(() => _citySearching = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = Uri.parse('${BASE_URL}master/city/list');
      final body = {
        "cityName": q,
        if (_selectedStateId != null) "state_id": _selectedStateId,
      };

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      // 🔴 NEW: 401/403 → force logout
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        _forceLogoutFromResponse(resp);
        return;
      }

      // ✅ 406 → subscription expired
      if (resp.statusCode == 406) {
        _openSubscriptionPageAndStop();
        return;
      }

      if (resp.statusCode == 200) {
        final root = jsonDecode(resp.body) as Map<String, dynamic>;
        final ok = root['status'] == true;
        final list = (root['data'] as List?) ?? [];
        final parsed = list
            .map((e) => _CityItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        setState(() => _cities = ok ? parsed : []);
      } else {
        setState(() => _cities = []);
      }
    } catch (_) {
      setState(() => _cities = []);
    } finally {
      if (mounted) setState(() => _citySearching = false);
    }
  }

  // Resolve selected city name by id (on load)
  Future<void> _resolveCityNameForId(int cityId, int? stateId) async {
    debugPrint("🧭 [resolve] start cityId=$cityId stateId=$stateId");
    if (cityId == 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 0) Cache
      final cached = prefs.getString('city_name_$cityId');
      debugPrint("🧭 [resolve] cache city_name_$cityId => $cached");
      if (cached != null && cached.isNotEmpty) {
        if (mounted) setState(() => _selectedCityName = cached);
        return;
      }

      final token = prefs.getString('auth_token');
      final url = Uri.parse('${BASE_URL}master/city/list');

      // Helper: ek request bhejo, parse karke id=cityId match return karo
      Future<_CityItem?> tryFetch(Map<String, dynamic> body, String tag) async {
        debugPrint("🌐 [resolve/$tag] POST $url body=$body");
        final resp = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            if (token != null && token.isNotEmpty)
              "Authorization": "Bearer $token",
          },
          body: jsonEncode(body),
        );
        // 🔴 NEW: 401/403 → force logout
        if (resp.statusCode == 401 || resp.statusCode == 403) {
          _forceLogoutFromResponse(resp);
          return null;
        }

        // ✅ 406 → subscription expired
        if (resp.statusCode == 406) {
          _openSubscriptionPageAndStop();
          return null;
        }

        debugPrint("🌐 [resolve/$tag] status=${resp.statusCode}");
        if (resp.statusCode != 200) {
          debugPrint(
            "💥 [resolve/$tag] non-200 body.head=${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}",
          );
          return null;
        }

        final root = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (root['data'] as List?) ?? [];
        debugPrint("🌐 [resolve/$tag] len=${list.length}");
        if (list.isNotEmpty) {
          debugPrint(
            "🌐 [resolve/$tag] first keys=${(list.first as Map).keys.toList()}",
          );
        }

        final parsed = list
            .map((e) => _CityItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        // Debug: id set print
        final idsPreview = parsed.take(10).map((c) => c.id).toList();
        debugPrint("🧾 [resolve/$tag] sample ids=$idsPreview");

        for (final c in parsed) {
          if (c.id == cityId) {
            debugPrint("✅ [resolve/$tag] MATCH id=${c.id} name='${c.name}'");
            return c;
          }
        }
        debugPrint("🚫 [resolve/$tag] no match in this page/batch");
        return null;
      }

      _CityItem? hit;

      // 1) Direct id filters (common variants)
      hit ??= await tryFetch({"id": cityId}, "byId");
      hit ??= await tryFetch({"city_id": cityId}, "byCityId");
      hit ??= await tryFetch({"cityId": cityId}, "byCityIdCamel");

      // 2) State-scoped big list (agar API support kare): limit/per_page/page_size guesses
      hit ??= await tryFetch({
        "cityName": "",
        if (stateId != null) "state_id": stateId,
        "limit": 10000,
      }, "stateLimit");
      hit ??= await tryFetch({
        "cityName": "",
        if (stateId != null) "state_id": stateId,
        "per_page": 10000,
      }, "statePerPage");
      hit ??= await tryFetch({
        "cityName": "",
        if (stateId != null) "state_id": stateId,
        "page_size": 10000,
      }, "statePageSize");

      // 3) Global big list fallback (no state)
      if (hit == null) {
        hit ??= await tryFetch({"cityName": "", "limit": 10000}, "allLimit");
        hit ??= await tryFetch({
          "cityName": "",
          "per_page": 10000,
        }, "allPerPage");
        hit ??= await tryFetch({
          "cityName": "",
          "page_size": 10000,
        }, "allPageSize");
      }

      if (hit != null && hit.name.isNotEmpty) {
        await prefs.setString('city_name_$cityId', hit.name);
        if (mounted) {
          setState(() => _selectedCityName = hit!.name);
          debugPrint("🧭 [resolve] setState name='${hit!.name}' ✅");
        }
        return;
      }

      // 4) Still not found → show fallback label (optional)
      debugPrint(
        "🧭 [resolve] FINAL: cityId=$cityId not found via all strategies",
      );
      if (mounted) setState(() => _selectedCityName = "Unknown (#$cityId)");
    } catch (e, st) {
      debugPrint("💥 [resolve] error: $e");
      debugPrint("📜 $st");
    }
  }

  Future<void> _openCityPicker() async {
    final textCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) async {
                      await _searchCities(v);
                      setSheetState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Search City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      suffixIcon: _citySearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () async {
                                await _searchCities(textCtrl.text);
                                setSheetState(() {});
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: _cities.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Type to search cities...'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: _cities.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = _cities[i];
                              final selected = c.id == _selectedCityId;
                              return ListTile(
                                title: Text(c.name),
                                trailing: selected
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xff005E6A),
                                      )
                                    : null,
                                onTap: () async {
                                  setState(() {
                                    _selectedCityId = c.id;
                                    _selectedCityName = c.name;
                                  });
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString(
                                    'city_name_${c.id}',
                                    c.name,
                                  ); // 🔒 cache
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    // textCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCityLabel = _selectedCityName ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff003840)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Company Profile',
          style: TextStyle(color: Color(0xff003840)),
        ),
      ),
      body: _loading
          ? const _CompanyProfileSkeleton()
          //     : _error != null
          //     ? OopsPage(
          //   failure: ApiHttpFailure(statusCode: null, body: _error),
          // )
          : _error != null
          ? (() {
              final maybeCode = _extractStatusCodeFromText(_error);
              if (_looksLikeSubscriptionExpired(
                code: maybeCode,
                body: _error,
              )) {
                // Bloc-builder waali style: directly page dikha do
                return const SubscriptionExpiredScreen();
              }
              return OopsPage(
                failure: ApiHttpFailure(statusCode: maybeCode, body: _error),
              );
            })()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Logo
                  InkWell(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        final p = result.files.single.path!;
                        setState(() => _logoPathOrUrl = p); // preview update
                        await _uploadCompanyLogo(p); // 🔥 API CALL
                      }
                    },

                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xff003840),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageProviderFrom(_logoPathOrUrl),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff003840),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              final p = result.files.single.path!;
                              setState(
                                () => _logoPathOrUrl = p,
                              ); // preview update
                              await _uploadCompanyLogo(p); // 🔥 API CALL
                            }
                          },
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: const Text(
                            'Upload Logo',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fields (with * and errorText)
                  _buildMultiline("Company Profile", _companyProfileCtrl),
                  _buildField(
                    "Company Name *",
                    _companyNameCtrl,
                    error: _errCompanyName,
                  ),
                  _buildField(
                    "Executive Name *",
                    _executiveNameCtrl,
                    error: _errExecutiveName,
                  ),
                  _buildField(
                    "Executive Email *",
                    _executiveEmailCtrl,
                    error: _errExecutiveEmail,
                  ),
                  _buildField(
                    "Executive Mobile",
                    _executiveMobileCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildField(
                    "Company Website *",
                    _websiteCtrl,
                    error: _errWebsite,
                  ),
                  _buildField("Company Size *", _sizeCtrl, error: _errSize),
                  _buildMultiline(
                    "Company Address *",
                    _addressCtrl,
                    error: _errAddress,
                  ),

                  // State dropdown (search)
                  _buildStateDropdown(),

                  // City picker façade
                  _buildCityDropdownFacade(selectedCityLabel),

                  _buildField(
                    "Postal Code *",
                    _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    error: _errPincode,
                  ),

                  const SizedBox(height: 20),
                  _submitting
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            final ok = await _showConfirmDialog(
                              context,
                              "Are you sure you want to change your Company Details?",
                            );
                            if (ok != true) return;

                            // Validate after confirmation
                            if (!_validateRequired()) {
                              // error flags set + snackbar shown
                              return;
                            }

                            if (!mounted) return;
                            await _submit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff005E6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                            child: Text(
                              "Update",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  // ------ UI pieces ------
  Widget _buildField(
    String label,
    TextEditingController c, {
    TextInputType? keyboardType,
    bool error = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label.replaceAll('*', '').trim(),
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              children: label.contains('*')
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ]
                  : [],
            ),
          ),
          errorText: error ? 'Required' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onChanged: (_) {
          if (error) setState(() {});
        },
      ),
    );
  }

  // Widget _buildField(String label, TextEditingController c,
  //     {TextInputType? keyboardType, bool error = false}) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15),
  //     child: TextFormField(
  //       controller: c,
  //       keyboardType: keyboardType,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         errorText: error ? 'Required' : null,
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
  //       ),
  //       onChanged: (_) {
  //         // live clear error
  //         if (error) setState(() {});
  //       },
  //     ),
  //   );
  // }

  Widget _buildMultiline(
    String label,
    TextEditingController c, {
    bool error = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: c,
        maxLines: 4,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label.replaceAll('*', '').trim(),
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              children: label.contains('*')
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ]
                  : [],
            ),
          ),
          errorText: error ? 'Required' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onChanged: (_) {
          if (error) setState(() {});
        },
      ),
    );
  }

  // Widget _buildMultiline(String label, TextEditingController c, {bool error = false}) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15),
  //     child: TextFormField(
  //       controller: c,
  //       maxLines: 4,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         errorText: error ? 'Required' : null,
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
  //       ),
  //       onChanged: (_) {
  //         if (error) setState(() {});
  //       },
  //     ),
  //   );
  // }

  // State Dropdown with Search
  Widget _buildStateDropdown() {
    final items = _states.where((s) => s.name.trim().isNotEmpty).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownSearch<int>(
            items: items.map((s) => s.id).toList(),
            selectedItem: _selectedStateId,
            itemAsString: (id) => items.firstWhere((s) => s.id == id).name,

            // 👇 NEW: selected value (closed field) ka custom UI with bigger text
            dropdownBuilder: (context, int? id) {
              final label = (id == null)
                  ? 'Select State'
                  : items.firstWhere((s) => s.id == id).name;
              return Text(
                label,
                style: const TextStyle(
                  fontSize: 16, // 🔥 bigger size
                  // fontWeight: FontWeight.w600,
                  // color: Color(0xff003840),
                ),
                overflow: TextOverflow.ellipsis,
              );
            },

            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                label: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'State ',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16, // 🔥 label bhi bigger
                          // fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          // fontSize: 18,            // 🔥 asterisk size match
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                errorText: _errState ? 'Required' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),

            // (optional) Popup list items ka size thoda bada
            popupProps: PopupProps.dialog(
              showSearchBox: true,
              itemBuilder: (context, int id, bool isSelected) {
                final name = items.firstWhere((s) => s.id == id).name;
                return ListTile(
                  dense: false,
                  title: Text(name, style: const TextStyle(fontSize: 16)),
                  selected: isSelected,
                );
              },
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  labelText: "Search state...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            onChanged: (val) {
              setState(() {
                _selectedStateId = val;
                _cities = [];
                _selectedCityId = null;
                _selectedCityName = null;
              });
            },
          ),

          // DropdownSearch<int>(
          //   items: items.map((s) => s.id).toList(),
          //   selectedItem: _selectedStateId,
          //   itemAsString: (id) => items.firstWhere((s) => s.id == id).name,
          //   dropdownDecoratorProps: DropDownDecoratorProps(
          //     dropdownSearchDecoration: InputDecoration(
          //       label: Text.rich(
          //         TextSpan(
          //           children: [
          //             const TextSpan(
          //               text: 'State ',
          //               style: TextStyle(color: Colors.black54),
          //             ),
          //             const TextSpan(
          //               text: '*',
          //               style: TextStyle(color: Colors.red),
          //             ),
          //           ],
          //         ),
          //       ),
          //       errorText: _errState ? 'Required' : null,
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(28),
          //       ),
          //     ),
          //   ),
          //   popupProps: PopupProps.dialog(
          //     showSearchBox: true,
          //     searchFieldProps: TextFieldProps(
          //       decoration: InputDecoration(
          //         labelText: "Search state...",
          //         border: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(30),
          //         ),
          //       ),
          //     ),
          //   ),
          //   onChanged: (val) {
          //     setState(() {
          //       _selectedStateId = val;
          //       _cities = [];
          //       _selectedCityId = null;
          //       _selectedCityName = null;
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  // Widget _buildStateDropdown() {
  //   final items = _states.where((s) => s.name.trim().isNotEmpty).toList()
  //     ..sort((a, b) => a.name.compareTo(b.name));
  //
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // label line with asterisk look (kept via labelText below too)
  //         DropdownSearch<int>(
  //           items: items.map((s) => s.id).toList(),
  //           selectedItem: _selectedStateId,
  //           itemAsString: (id) => items.firstWhere((s) => s.id == id).name,
  //           dropdownDecoratorProps: DropDownDecoratorProps(
  //             dropdownSearchDecoration: InputDecoration(
  //               labelText: "State *",
  //               errorText: _errState ? 'Required' : null,
  //               border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
  //             ),
  //           ),
  //           popupProps: PopupProps.dialog(
  //             showSearchBox: true,
  //             searchFieldProps: TextFieldProps(
  //               decoration: InputDecoration(
  //                 labelText: "Search state...",
  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(30),
  //                 ),
  //               ),
  //             ),
  //           ),
  //           onChanged: (val) {
  //             setState(() {
  //               _selectedStateId = val;
  //               _cities = [];
  //               _selectedCityId = null;
  //               _selectedCityName = null;
  //             });
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // City façade (looks like dropdown)
  Widget _buildCityDropdownFacade(String? selectedCityLabel) {
    debugPrint(
      "🧱 [buildCity] _selectedCityId=$_selectedCityId label='$selectedCityLabel'",
    );

    final items = <DropdownMenuItem<int>>[];

    final needsResolve =
        _selectedCityId != null &&
        (selectedCityLabel == null || selectedCityLabel.isEmpty);
    if (needsResolve) {
      debugPrint("🧱 [buildCity] needsResolve=true → calling resolve");
      Future.microtask(
        () => _resolveCityNameForId(_selectedCityId!, _selectedStateId),
      );
    }
    // 👆 add block ends

    if (_selectedCityId != null) {
      debugPrint('✅ City Dropdown: _selectedCityId = $_selectedCityId');
      debugPrint('✅ City Dropdown: selectedCityLabel = $selectedCityLabel');

      items.add(
        DropdownMenuItem<int>(
          value: _selectedCityId!,
          child: Text(
            (selectedCityLabel != null && selectedCityLabel.isNotEmpty)
                ? selectedCityLabel
                : 'Select City',
            style: TextStyle(
              fontWeight:
                  (selectedCityLabel != null && selectedCityLabel.isNotEmpty)
                  ? FontWeight.normal
                  : FontWeight.normal,
            ),
          ),
        ),
      );

      debugPrint(
        '✅ City Dropdown item added: ${(selectedCityLabel != null && selectedCityLabel.isNotEmpty) ? selectedCityLabel : 'Select City'}',
      );
    } else {
      debugPrint('⚠️ _selectedCityId is NULL, no city added in dropdown');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => _openCityPicker(),
        borderRadius: BorderRadius.circular(8),
        child: AbsorbPointer(
          child: DropdownButtonFormField<int>(
            value: _selectedCityId,
            onChanged: (_) {},
            items: items,
            decoration: InputDecoration(
              label: RichText(
                text: TextSpan(
                  text: 'City ',
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                  children: const [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              errorText: _errCity ? 'Required' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            hint: const Text("Select City"),
          ),
        ),
      ),
    );
  }

  // Widget _buildCityDropdownFacade(String? selectedCityLabel) {
  //   final items = <DropdownMenuItem<int>>[];
  //   if (_selectedCityId != null) {
  //     items.add(
  //       DropdownMenuItem<int>(
  //         value: _selectedCityId!,
  //         child: Text(
  //           (selectedCityLabel != null && selectedCityLabel.isNotEmpty)
  //               ? selectedCityLabel        // ✅ actual city name
  //               : 'Select City',           // ✅ fallback text
  //         ),
  //       ),
  //     );
  //   }
  //
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15),
  //     child: InkWell(
  //       onTap: () => _openCityPicker(),
  //       borderRadius: BorderRadius.circular(8),
  //       child: AbsorbPointer(
  //         child: DropdownButtonFormField<int>(
  //           value: _selectedCityId,
  //           onChanged: (_) {},
  //           items: items,
  //           decoration: InputDecoration(
  //             labelText: "City *",
  //             errorText: _errCity ? 'Required' : null,
  //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
  //           ),
  //           icon: const Icon(Icons.arrow_drop_down),
  //           hint: const Text("Select City"),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ---------- Confirm dialog ----------
  Future<bool> _showConfirmDialog(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 48,
                  color: Color(0xff005E6A),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Confirmation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff005E6A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  // ---------- Validation ----------
  bool _validateRequired() {
    final cn = _companyNameCtrl.text.trim();
    final en = _executiveNameCtrl.text.trim();
    final ee = _executiveEmailCtrl.text.trim();
    final web = _websiteCtrl.text.trim();
    final size = _sizeCtrl.text.trim();
    final addr = _addressCtrl.text.trim();
    final pin = _pincodeCtrl.text.trim();

    final missing = <String>[];

    _errCompanyName = cn.isEmpty;
    if (_errCompanyName) missing.add('Company Name');

    _errExecutiveName = en.isEmpty;
    if (_errExecutiveName) missing.add('Executive Name');

    _errExecutiveEmail = ee.isEmpty;
    if (_errExecutiveEmail) missing.add('Executive Email');

    _errWebsite = web.isEmpty;
    if (_errWebsite) missing.add('Company Website');

    _errSize = size.isEmpty;
    if (_errSize) missing.add('Company Size');

    _errAddress = addr.isEmpty;
    if (_errAddress) missing.add('Company Address');

    _errPincode = pin.isEmpty;
    if (_errPincode) missing.add('Pincode');

    _errState = (_selectedStateId == null);
    if (_errState) missing.add('State');

    _errCity = (_selectedCityId == null);
    if (_errCity) missing.add('City');

    setState(() {}); // refresh error visuals

    if (missing.isNotEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Please fill: ${missing.join(', ')}'),
      //     backgroundColor: Colors.red,
      //     duration: const Duration(seconds: 2),
      //   ),
      // );
      ShowErrorSnack(context, 'Please fill: ${missing.join(', ')}');
      return false;
    }
    return true;
  }

  void ShowErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ), // ✅ Rectangular with little radius
        ),
        duration: Duration(seconds: 2),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }


  // --- upload company logo via SAS → Azure → update-profile-pic ---
  Future<void> _uploadCompanyLogo(String localPath) async {
    try {
      debugPrint('🟡 [_uploadCompanyLogo] start with localPath=$localPath');

      // 1) File info
      final file = File(localPath);
      if (!file.existsSync()) {
        ShowErrorSnack(context, 'Selected file not found.');
        return;
      }
      final fileSize = await file.length();
      final contentType = _detectContentType(localPath); // e.g. image/png
      final ext = _extensionOf(localPath).isEmpty
          ? 'png'
          : _extensionOf(localPath);

      // 2) Auth token (if required by SAS API)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // 3) Build SAS token URL (use your real base for SAS)

      final folderName =
          'company_logo/${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      // unique file name
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'company-logo-$ts.$ext';

      final sasUri = Uri.parse('${BASE_URL}common/sas-token').replace(
        queryParameters: {
          'folderName': folderName,
          'filesName': fileName,
          'filesSize': fileSize.toString(),
          'filesType': contentType, // <<<< e.g. image/png
        },
      );

      debugPrint('🟢 [SAS] GET $sasUri');

      final sasResp = await http.get(
        sasUri,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🟢 [SAS] status=${sasResp.statusCode}');
      debugPrint(
        '🟢 [SAS] body.head=${sasResp.body.length > 200 ? sasResp.body.substring(0, 200) : sasResp.body}',
      );

      if (sasResp.statusCode != 200) {
        ShowErrorSnack(
          context,
          'Failed to get SAS token (${sasResp.statusCode}).',
        );
        return;
      }

      final sasJson = json.decode(sasResp.body);
      final ok = (sasJson['status'] == true);
      if (!ok) {
        ShowErrorSnack(context, 'SAS status false.');
        return;
      }

      final String sasUrl = (sasJson['sas_url'] ?? '').toString();
      // API ne `blob_url` bhi diya hai; upload success ke baad wohi final Hoga (without query)
      final String apiBlobUrl = (sasJson['blob_url'] ?? '').toString();

      if (sasUrl.isEmpty) {
        ShowErrorSnack(context, 'Invalid SAS response.');
        return;
      }

      // 4) PUT to Azure Blob with sas_url
      final uploadedUrl = await _uploadToAzureWithSas(
        sasUrl,
        file,
        contentType: contentType,
      );
      if (uploadedUrl == null) {
        ShowErrorSnack(context, 'Azure upload failed.');
        return;
      }
      // Prefer server-provided blob_url when present (clean, no query)
      final cleanBlobUrl = (apiBlobUrl.isNotEmpty) ? apiBlobUrl : uploadedUrl;

      debugPrint('✅ [Azure] blobUrl=$cleanBlobUrl');

      if (!mounted) return;

      // 5) Call your existing update-profile-pic API with clean URL (no query)
      final url = Uri.parse('${BASE_URL}profile/update-profile-pic');
      final body = {
        'profile_url': cleanBlobUrl,
        'profile_action': 'company-profile-pic',
      };

      debugPrint('🟡 [UpdateProfilePic] POST $url');
      debugPrint('🟡 [UpdateProfilePic] body=$body');

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // 🔴 NEW: 401/403 → force logout
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        _forceLogoutFromResponse(resp);
        return;
      }
      // ✅ 406 → subscription expired
      if (resp.statusCode == 406) {
        _openSubscriptionPageAndStop();
        return;
      }

      debugPrint('🟢 [UpdateProfilePic] status=${resp.statusCode}');
      debugPrint(
        '🟢 [UpdateProfilePic] body.head=${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}',
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        showSuccessSnackBar(context, 'Logo updated successfully');
        // preview ko server URL pe set kar do (FileImage se NetworkImage)
        setState(() => _logoPathOrUrl = cleanBlobUrl);
        // optionally fresh data
        await _loadCompanyDetail();
        await CompanyInfoManager().setCompanyData(
          CompanyInfoManager().companyName, // name same rahe to bhi chalega
          cleanBlobUrl, // API ka naya blob URL (SAS ho to bhi chalega)
        );
      } else {
        ShowErrorSnack(context, 'Logo update failed (${resp.statusCode}).');
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('🔥 [_uploadCompanyLogo] error: $e');
      debugPrint('📜 stack: $st');
      ShowErrorSnack(context, 'Logo update error: $e');
    }
  }

  String _detectContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    // fallback (logo ke liye image/* hi rahe)
    return 'application/octet-stream';
  }

  String _extensionOf(String path) {
    final i = path.lastIndexOf('.');
    if (i == -1) return '';
    return path.substring(i + 1).toLowerCase();
  }

  /// Azure PUT (sas_url) —> returns blob url without query (or null on failure)
  Future<String?> _uploadToAzureWithSas(
    String sasUrl,
    File file, {
    required String contentType,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      final req = http.Request("PUT", Uri.parse(sasUrl));
      req.headers.addAll({
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': contentType, // <<<< image/png / image/jpeg ...
      });
      req.bodyBytes = bytes;

      final res = await req.send();
      final body = await res.stream.bytesToString();

      debugPrint("Azure PUT status: ${res.statusCode}");
      debugPrint(
        "Azure PUT body.head: ${body.length > 160 ? body.substring(0, 160) : body}",
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        // sasUrl without query
        return sasUrl.split('?').first;
      }
      return null;
    } catch (e) {
      debugPrint("Azure PUT error: $e");
      return null;
    }
  }

  void _goBackToAccount() {
    // Close keyboard & give a tiny delay so snackbar flash ho sake
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        // Agar yeh screen Account se aayi hai to pop karke wahi par le jao
        Navigator.pop(context, true); // <- result: updated
      } else {
        // Fallback: agar stack me kuch nahi hai to named route use karo
        Navigator.of(context).pushReplacementNamed(
          '/account',
        ); // <- apni route name ho to yahan set karo
      }
    });
  }

  //   Future<void> _uploadCompanyLogo(String pathOrUrl) async {
  //     try {
  //       print('🟡 [DEBUG] Starting _uploadCompanyLogo...');
  //       print('🟢 [DEBUG] Received pathOrUrl: $pathOrUrl');
  //
  //       // get auth token
  //       final prefs = await SharedPreferences.getInstance();
  //       final token = prefs.getString('auth_token');
  //       print('🟢 [DEBUG] Retrieved token: ${token != null ? 'Token found ✅' : 'Token missing ❌'}');
  //
  //       // build URL
  //       final url = Uri.parse(
  //         '${BASE_URL}/profile/update-profile-pic',
  //       );
  //       print('🟢 [DEBUG] API endpoint: $url');
  //
  //       // prepare request body
  //       final body = {
  //         "profile_url": pathOrUrl, // <- yahi path/URL bhejna hai
  //         "profile_action": "company-profile-pic"
  //       };
  //       print('🟢 [DEBUG] Request body: $body');
  //
  //       // make POST request
  //       print('🟡 [DEBUG] Sending POST request...');
  //       final resp = await http.post(
  //         url,
  //         headers: {
  //           "Content-Type": "application/json",
  //           if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
  //         },
  //         body: jsonEncode(body),
  //       );
  //       print('🟢 [DEBUG] Response status: ${resp.statusCode}');
  //       print('🟢 [DEBUG] Response body: ${resp.body}');
  //
  //       if (!mounted) {
  //         print('⚠️ [DEBUG] Widget not mounted anymore, stopping execution.');
  //         return;
  //       }
  //
  //       // check response status
  //       if (resp.statusCode == 200) {
  //         print('✅ [DEBUG] Logo updated successfully!');
  //         ShowSuccesSnackbar(context, 'Logo updated successfully');
  //       } else {
  //         print('❌ [DEBUG] Logo update failed (${resp.statusCode})');
  //         ShowErrorSnack(context, 'Logo update failed (${resp.statusCode})');
  //       }
  //     } catch (e, st) {
  //       if (!mounted) return;
  //       print('🔥 [DEBUG] Exception in _uploadCompanyLogo: $e');
  //       print('📜 [DEBUG] StackTrace:\n$st');
  //       ShowErrorSnack(context, 'Logo update error: $e');
  //     }
  //   }
}

class _CompanyProfileSkeleton extends StatelessWidget {
  const _CompanyProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Logo + button skeleton
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xff003840),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.white60,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff003840),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text(
                    'Upload Logo',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 🔹 Multiple textfield-like skeletons
            _skeletonField(),
            _skeletonField(),
            _skeletonField(),
            _skeletonField(),
            _skeletonField(),
            _skeletonField(),
            _skeletonMultiline(),
            _skeletonField(), // state
            _skeletonField(), // city
            _skeletonField(), // pincode

            const SizedBox(height: 20),

            // 🔹 Submit button skeleton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff005E6A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  child: Text(
                    "Update",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // single-line field placeholder
  Widget _skeletonField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // multiline field placeholder
  Widget _skeletonMultiline() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}


// Simple city DTO
class _CityItem {
  final int id;
  final String name;
  final int? stateId;

  _CityItem({required this.id, required this.name, this.stateId});

  factory _CityItem.fromJson(Map<String, dynamic> j) {
    // 🔎 raw dump (short):
    debugPrint("🧩 CITY JSON: ${j.keys.toList()}");

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final idRaw = j['id'] ?? j['city_id'] ?? j['value']; // common aliases
    final stateRaw = j['state_id'] ?? j['stateId'];

    // name aliases: name, city_name, title, label
    final nameRaw =
        (j['name'] ?? j['city_name'] ?? j['title'] ?? j['label'] ?? '')
            .toString();

    return _CityItem(
      id: parseInt(idRaw),
      name: nameRaw,
      stateId: stateRaw == null ? null : parseInt(stateRaw),
    );
  }
}
