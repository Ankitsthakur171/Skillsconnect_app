import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Utilities/BookmarkList_api.dart';
import '../../../blocpage/BookmarkBloc/bookmarkLogic.dart';
import '../../../blocpage/BookmarkBloc/bookmarkEvent.dart';
import '../../JobTab/JobdetailPage/JobdetailpageBT.dart';

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  bool _loading = true;
  List<BookmarkJob> _items = [];
  String _error = '';
  static const double _scale = 0.95;


  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final items =
          await BookmarkApi.fetchBookmarks(module: 'Job', page: 1, limit: 50);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      print('[WatchList] _loadBookmarks: loaded ${_items.length} items');
    } catch (e, st) {
      print('[WatchList] _loadBookmarks error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load bookmarks';
      });
    }

    try {
      final bloc = context.read<BookmarkBloc?>();
      if (bloc != null) {}
    } catch (_) {}
  }

  Future<void> _reloadBookmarksSilently() async {
    try {
      final items =
          await BookmarkApi.fetchBookmarks(module: 'Job', page: 1, limit: 50);
      if (!mounted) return;
      final changed =
          items.length != _items.length || !_listEqualsById(items, _items);
      if (changed) {
        setState(() {
          _items = items;
        });
        print('[WatchList] _reloadBookmarksSilently: updated list (silent)');
      } else {
        print('[WatchList] _reloadBookmarksSilently: no change');
      }
    } catch (e) {
      print('[WatchList] _reloadBookmarksSilently error: $e');
      // keep silent on errors
    }
  }

  bool _listEqualsById(List<BookmarkJob> a, List<BookmarkJob> b) {
    if (a.length != b.length) return false;
    // build sets of keys for faster compare
    final sa = <String>{};
    final sb = <String>{};
    for (final i in a) {
      sa.add('${i.entityId}-${i.moduleId}-${i.bookmarkId}');
    }
    for (final i in b) {
      sb.add('${i.entityId}-${i.moduleId}-${i.bookmarkId}');
    }
    return sa.containsAll(sb) && sb.containsAll(sa);
  }

  // Future<void> _removeBookmarkLocalAndRemote(BookmarkJob job) async {
  //   final removed = await BookmarkApi.removeBookmark(
  //       bookmarkId: job.bookmarkId, entityId: job.entityId, module: job.module);
  //   if (removed) {
  //     if (!mounted) return;
  //     setState(() {
  //       _items.removeWhere((e) =>
  //           e.bookmarkId == job.bookmarkId || e.entityId == job.entityId);
  //     });
  //
  //     try {
  //       final tokenOrTitle = job.jobToken ?? job.title;
  //       context.read<BookmarkBloc>().add(RemoveBookmarkEvent(tokenOrTitle));
  //     } catch (_) {}
  //     print(
  //         '[WatchList] _removeBookmarkLocalAndRemote: removed ${job.entityId}');
  //   } else {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Failed to remove bookmark')));
  //   }
  // }

  Future<void> _navigateIfOnline({
    required String jobToken,
    required int jobId,
    String? slug,
  }) async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (!online) {
        _showNoInternetSnackBar();
        return;
      }

      print(
          '[WatchList] navigating -> jobToken="$jobToken", jobId=$jobId, slug="$slug"');

      final popped = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailPage2(
            jobToken: jobToken,
            moduleId: jobId,
            slug: slug,
          ),
        ),
      );

      print('[WatchList] returned from JobDetailPage2 popped=$popped');

      if (popped == true) {
        if (mounted) {
          setState(() {
            _items.removeWhere((e) =>
                e.entityId == jobId ||
                e.moduleId == jobId ||
                e.bookmarkId.toString() == jobToken);
          });
        }
        try {
          await Future.delayed(const Duration(milliseconds: 150));
          if (!mounted) return;
          await _reloadBookmarksSilently();
        } catch (e) {
          print('[WatchList] reload after pop failed: $e');
        }
      } else {
        print('[WatchList] Detail returned false/null -> no reload');
      }
    } on SocketException {
      _showNoInternetSnackBar();
    } on TimeoutException {
      _showNoInternetSnackBar();
    } catch (e) {
      print('[WatchList] _navigateIfOnline unexpected error: $e');
    }
  }

  void _showNoInternetSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No internet connection')));
  }

  Widget _buildThinCard(BuildContext context, BookmarkJob job) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color(0xFF5799A3),
          width: 0.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          final passToken = (job.jobToken?.isNotEmpty ?? false)
              ? job.jobToken!
              : job.entityId.toString();
          final moduleId = job.moduleId;
          await _navigateIfOnline(jobToken: passToken, jobId: moduleId);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        job.companyLogo != null && job.companyLogo!.isNotEmpty
                            ? Image.network(
                                job.companyLogo!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.business,
                                      size: 20, color: Colors.grey),
                                ),
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.business,
                                    size: 20, color: Colors.grey),
                              ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.company,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003840),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.title,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  (job.ctc != null && job.ctc!.trim().isNotEmpty)
                      ? Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${job.ctc} LPA',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003840),
                            ),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.only(left: 8),
                          child: const Text(
                            'Unpaid',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF003840),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Color(0xFFBCD8DB),
                    ),
                    child: Text(
                      job.employmentType,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF003840)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Color(0xFFBCD8DB),
                    ),
                    child: Text(
                      job.opportunityType,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF003840)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(job.bookmarkedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF003840),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Card(
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 12,
                              width: double.infinity,
                              color: Colors.white),
                          const SizedBox(height: 6),
                          Container(
                              height: 10, width: 150, color: Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 60, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(height: 18, width: 90, color: Colors.white),
                    const SizedBox(width: 8),
                    Container(height: 18, width: 90, color: Colors.white),
                    const Spacer(),
                    Container(height: 12, width: 60, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Watchlist",
          style: TextStyle(
            color: Color(0xFF003840),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF003840)),
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? _buildShimmerList()
          : _items.isEmpty
              ? Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/No_Assessment.png',
                          width: 320 * _scale,
                          height: 240 * _scale,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 18 * _scale),
                        const Center(
                          child: Text(
                            "No bookmarked jobs yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookmarks,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final job = _items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildThinCard(context, job),
                      );
                    },
                  ),
                ),
    );
  }
}
