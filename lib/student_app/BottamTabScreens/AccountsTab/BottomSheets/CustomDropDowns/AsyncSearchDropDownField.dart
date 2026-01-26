import 'dart:async';
import 'package:flutter/material.dart';

class AsyncSearchableDropdownField extends StatefulWidget {
  final Map<String, String>? value;
  final Future<List<Map<String, String>>> Function({int page, String? query})
      fetcher;
  final void Function(Map<String, String>?) onChanged;
  final String label;

  const AsyncSearchableDropdownField({
    super.key,
    required this.value,
    required this.fetcher,
    required this.onChanged,
    this.label = "Select an option",
  });

  @override
  State<AsyncSearchableDropdownField> createState() =>
      _AsyncSearchableDropdownFieldState();
}

class _AsyncSearchableDropdownFieldState
    extends State<AsyncSearchableDropdownField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  String? _query;
  Timer? _debounce;

  bool _hasEverOpened = false;

  void Function(void Function())? _overlaySetState;

  static const int _pageSizeHint = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    debugPrint('[AsyncDropdown] initState');
  }

  @override
  void dispose() {
    debugPrint('[AsyncDropdown] dispose');
    _debounce?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _overlaySetState = null;
    super.dispose();
  }

  Future<void> _fetchInitial({String? query}) async {
    debugPrint('[AsyncDropdown] _fetchInitial start -> page=1 query="$query"');

    if ((_query ?? '') == (query ?? '') && _items.isNotEmpty) {
      debugPrint(
          '[AsyncDropdown] _fetchInitial - same query and cached items -> skip');
      return;
    }
    if ((_query ?? '') != (query ?? '')) {
      try {
        _scrollController.jumpTo(0);
      } catch (_) {}
    }

    setState(() {
      _loading = true;
      _page = 1;
      _items = [];
      _hasMore = true;
      _query = query;
    });
    _overlaySetState?.call(() {});
    try {
      final result = await widget.fetcher(page: _page, query: query);
      debugPrint(
          '[AsyncDropdown] fetcher returned ${result.length} items for page=$_page (query="$query")');
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, String>>.from(result);
        _loading = false;
        _hasMore = result.length >= _pageSizeHint;
      });
      _overlaySetState?.call(() {});
    } catch (e, st) {
      debugPrint('[AsyncDropdown] _fetchInitial ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasMore = false;
      });
      _overlaySetState?.call(() {});
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || !_hasMore) {
      debugPrint(
          '[AsyncDropdown] _fetchMore skipped (loadingMore=$_loadingMore, hasMore=$_hasMore)');
      return;
    }
    if (_loading) {
      debugPrint('[AsyncDropdown] _fetchMore waiting for initial load');
      return;
    }
    if (_items.isEmpty) {
      debugPrint('[AsyncDropdown] _fetchMore skipped because items empty');
      return;
    }

    setState(() => _loadingMore = true);
    _overlaySetState?.call(() {});
    final nextPage = _page + 1;
    debugPrint(
        '[AsyncDropdown] _fetchMore -> fetching page=$nextPage query="$_query');
    try {
      final result = await widget.fetcher(page: nextPage, query: _query);
      debugPrint(
          '[AsyncDropdown] fetchMore returned ${result.length} items for page=$nextPage');
      if (!mounted) return;
      setState(() {
        _page = nextPage;
        _items.addAll(result);
        _loadingMore = false;
        if (result.isEmpty || result.length < _pageSizeHint) _hasMore = false;
      });
      _overlaySetState?.call(() {});
    } catch (e, st) {
      debugPrint('[AsyncDropdown] _fetchMore ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _overlaySetState?.call(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    debugPrint(
        '[AsyncDropdown] scroll pos=${pos.pixels}, max=${pos.maxScrollExtent}');
    const threshold = 120.0;
    if (pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - threshold) {
      debugPrint('[AsyncDropdown] near bottom -> trigger _fetchMore()');
      _fetchMore();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      debugPrint('[AsyncDropdown] opening overlay');
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)!.insert(_overlayEntry!);

      if (!_hasEverOpened) {
        _hasEverOpened = true;
        _fetchInitial(query: null);
      } else {
        final currentQuery = _searchController.text.trim();
        if ((_query ?? '') != currentQuery) {
          _fetchInitial(query: currentQuery.isEmpty ? null : currentQuery);
        } else if (_items.isEmpty) {
          _fetchInitial(query: currentQuery.isEmpty ? null : currentQuery);
        } else {
          debugPrint(
              '[AsyncDropdown] overlay opened with cached ${_items.length} items (preserve scroll)');
        }
      }

      _focusNode.requestFocus();
    } else {
      debugPrint('[AsyncDropdown] closing overlay');
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.unfocus();
    debugPrint(
        '[AsyncDropdown] overlay removed (items cached=${_items.length})');
  }

  void _selectItem(Map<String, String> item) {
    debugPrint(
        '[AsyncDropdown] selected item id=${item['id']} text=${item['text']}');
    widget.onChanged(item);
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(builder: (context) {
      return Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: StatefulBuilder(
              builder: (context, overlaySetState) {
                // Save the overlay setState reference so we can refresh the overlay
                _overlaySetState = overlaySetState;

                return Container(
                  constraints: const BoxConstraints(maxHeight: 380),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      // Search field (live, debounced)
                      TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: "Search...",
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onChanged: (val) {
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            final q = val.trim();
                            debugPrint(
                                '[AsyncDropdown] search changed -> "$q" (debounced)');
                            _fetchInitial(query: q.isEmpty ? null : q);
                          });
                        },
                        onSubmitted: (_) {
                          // no-op; search is live
                          debugPrint(
                              '[AsyncDropdown] search submitted (ignored)');
                        },
                      ),

                      const SizedBox(height: 8),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _items.isEmpty
                                ? const Center(child: Text("No items found"))
                                : Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.zero,
                                      itemCount: _items.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index == _items.length) {
                                          if (_loadingMore) {
                                            return const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            if (!_hasMore) {
                                              return const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10),
                                                child: Center(
                                                    child:
                                                        Text("End of results")),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          }
                                        }

                                        final item = _items[index];

                                        if (index >= _items.length - 1 &&
                                            _hasMore) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            debugPrint(
                                                '[AsyncDropdown] itemBuilder reached last item -> prefetch next');
                                            _fetchMore();
                                          });
                                        }
                                        return ListTile(
                                          title: Text(item['text'] ?? ''),
                                          onTap: () => _selectItem(item),
                                          selected:
                                              widget.value?['id'] == item['id'],
                                          selectedTileColor:
                                              Colors.blue.shade50,
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: Icon(_overlayEntry == null
                ? Icons.arrow_drop_down
                : Icons.arrow_drop_up),
          ),
          child: Text(
            widget.value?['text'] ?? widget.label,
            style: TextStyle(
              color: widget.value == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
