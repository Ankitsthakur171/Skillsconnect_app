import 'dart:async';
import 'package:flutter/material.dart';

class AsyncCityDropdownField extends StatefulWidget {
  final String? value;
  final Future<Map<String, dynamic>> Function({int offset, String? query})
      fetcher;
  final void Function(String?) onChanged;
  final String label;
  final VoidCallback? onBeforeOpen;

  const AsyncCityDropdownField({
    super.key,
    required this.value,
    required this.fetcher,
    required this.onChanged,
    this.label = "Select a city",
    this.onBeforeOpen,
  });

  @override
  State<AsyncCityDropdownField> createState() =>
      _AsyncCityDropdownFieldState();
}

class _AsyncCityDropdownFieldState extends State<AsyncCityDropdownField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<String> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  int _offset = 0;
  bool _hasMore = true;
  String? _query;
  Timer? _debounce;

  bool _hasEverOpened = false;
  void Function(void Function())? _overlaySetState;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    print('[AsyncCityDropdown] initState');
  }

  @override
  void dispose() {
    print('[AsyncCityDropdown] dispose');
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
    print('[AsyncCityDropdown] _fetchInitial start -> offset=0 query="$query"');

    setState(() {
      _loading = true;
      _offset = 0;
      _items = [];
      _hasMore = true;
      _query = query;
    });
    _overlaySetState?.call(() {});

    try {
      final result = await widget.fetcher(offset: 0, query: query);
      final cities = (result['cities'] as List<String>?) ?? [];
      final hasMore = result['hasMore'] as bool? ?? false;

      print(
          '[AsyncCityDropdown] fetcher returned ${cities.length} items (hasMore=$hasMore)');

      if (!mounted) return;

      setState(() {
        _items = List<String>.from(cities);
        _loading = false;
        _hasMore = hasMore;
        _offset = cities.length;
      });
      _overlaySetState?.call(() {});
    } catch (e, st) {
      print('[AsyncCityDropdown] _fetchInitial ERROR: $e\n$st');
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
      print(
          '[AsyncCityDropdown] _fetchMore skipped (loadingMore=$_loadingMore, hasMore=$_hasMore)');
      return;
    }
    if (_loading) {
      print('[AsyncCityDropdown] _fetchMore waiting for initial load');
      return;
    }
    if (_items.isEmpty) {
      print('[AsyncCityDropdown] _fetchMore skipped because items empty');
      return;
    }

    setState(() => _loadingMore = true);
    _overlaySetState?.call(() {});

    print(
        '[AsyncCityDropdown] _fetchMore -> fetching offset=$_offset query="$_query"');

    try {
      final result = await widget.fetcher(offset: _offset, query: _query);
      final cities = (result['cities'] as List<String>?) ?? [];
      final hasMore = result['hasMore'] as bool? ?? false;

      print('[AsyncCityDropdown] fetchMore returned ${cities.length} cities');

      if (!mounted) return;

      setState(() {
        _items.addAll(cities);
        _loadingMore = false;
        _hasMore = hasMore;
        _offset += cities.length;
      });
      _overlaySetState?.call(() {});
    } catch (e, st) {
      print('[AsyncCityDropdown] _fetchMore ERROR: $e\n$st');
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _overlaySetState?.call(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    const threshold = 100.0;
    if (pos.maxScrollExtent > 0 &&
        pos.pixels >= pos.maxScrollExtent - threshold) {
      print('[AsyncCityDropdown] near bottom -> trigger _fetchMore()');
      _fetchMore();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      widget.onBeforeOpen?.call();
      print('[AsyncCityDropdown] opening overlay');
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
          print(
              '[AsyncCityDropdown] overlay opened with cached ${_items.length} items');
        }
      }
    } else {
      print('[AsyncCityDropdown] closing overlay');
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.unfocus();
    print('[AsyncCityDropdown] overlay removed (items cached=${_items.length})');
  }

  void _selectItem(String item) {
    print('[AsyncCityDropdown] selected city: $item');
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
                // Save the overlay setState reference
                _overlaySetState = overlaySetState;

                return Container(
                  constraints: const BoxConstraints(maxHeight: 300),
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
                          hintText: "Search cities...",
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
                            final q = val.trim();
                            print(
                                '[AsyncCityDropdown] search changed -> "$q" (debounced)');
                            _fetchInitial(query: q.isEmpty ? null : q);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loading
                            ? const Center(
                                child: CircularProgressIndicator())
                            : _items.isEmpty
                                ? const Center(
                                    child: Text("No cities found"))
                                : Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      padding: EdgeInsets.zero,
                                      itemCount: _items.length + 1,
                                      itemBuilder: (context, index) {
                                        // Loading footer
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
                                          } else if (!_hasMore) {
                                            return const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10),
                                              child: Center(
                                                  child:
                                                      Text("All cities loaded")),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        }

                                        final city = _items[index];

                                        // Prefetch next page when reaching last item
                                        if (index >= _items.length - 3 &&
                                            _hasMore) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            print(
                                                '[AsyncCityDropdown] itemBuilder near last -> prefetch next');
                                            _fetchMore();
                                          });
                                        }

                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8),
                                          dense: true,
                                          title: Text(city),
                                          onTap: () => _selectItem(city),
                                          selected: widget.value == city,
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
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(
              _overlayEntry == null
                  ? Icons.arrow_drop_down
                  : Icons.arrow_drop_up,
            ),
          ),
          child: Text(
            widget.value?.isEmpty ?? true ? widget.label : widget.value!,
            style: TextStyle(
              color: (widget.value?.isEmpty ?? true)
                  ? Colors.grey
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
