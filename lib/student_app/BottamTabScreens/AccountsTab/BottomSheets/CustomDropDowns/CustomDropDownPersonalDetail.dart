import 'dart:async';
import 'package:flutter/material.dart';

class CustomFieldPersonalDetail extends StatefulWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  final String label;
  final VoidCallback? onBeforeTap;
  final VoidCallback? onLoadMore; // Callback when user scrolls to 90%

  const CustomFieldPersonalDetail(
      this.items,
      this.value,
      this.onChanged, {
        super.key,
        this.label = 'Select an option',
        this.onBeforeTap,
        this.onLoadMore,
      });

  @override
  State<CustomFieldPersonalDetail> createState() => _CustomFieldPersonalDetailState();
}

class _CustomFieldPersonalDetailState extends State<CustomFieldPersonalDetail> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late TextEditingController _searchController;
  late List<String> _filteredItems;
  final GlobalKey _key = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  late ScrollController _scrollController;
  Timer? _debounce;
  bool _loadMoreCalled = false; // Prevent multiple calls
  void Function(VoidCallback)? _setOverlayState; // Reference to overlay's setState

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items.toSet().toList();
    _scrollController = ScrollController();
    _focusNode.addListener(_handleFocusChange);
    print('Init: FocusNode created, hasFocus: ${_focusNode.hasFocus}');
  }

  @override
  void didUpdateWidget(CustomFieldPersonalDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When parent updates items (e.g., new cities loaded), update overlay
    if (oldWidget.items.length != widget.items.length) {
      print('didUpdateWidget: Items count changed from ${oldWidget.items.length} to ${widget.items.length}');
      // Update the overlay state if it's open
      if (_overlayEntry != null && _setOverlayState != null) {
        // Defer the setState call to after the current build frame is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_setOverlayState != null) {
            _setOverlayState?.call(() {
              final query = _searchController.text;
              if (query.isEmpty) {
                // No search: show all new items
                _filteredItems = widget.items.toSet().toList();
              } else {
                // With search: filter the new combined items
                _filteredItems = widget.items
                    .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                    .toSet()
                    .toList();
              }
              print('didUpdateWidget: Filtered items now: ${_filteredItems.length}');
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _removeOverlay();
    print('Dispose: Cleaning up');
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _filteredItems = widget.items.toSet().toList();
      _searchController.clear();
      _loadMoreCalled = false; // Reset flag when opening
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onBeforeTap?.call();
      });
      print('ToggleDropdown: Overlay created, showing ${_filteredItems.length} items');
    } else {
      _removeOverlay();
      _focusNode.unfocus();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.unfocus();
    print('RemoveOverlay: Overlay removed, Focus unfocused');
  }

  void _selectItem(String item) {
    widget.onChanged(item);
    _removeOverlay();
    print('SelectItem: Selected $item');
  }

  void _checkScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification || notification is ScrollEndNotification) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      const threshold = 100.0; // Load when within 100 pixels of bottom
      
      // If scrolled past 90% of max and more items might be available
      if (maxScroll > 0 && currentScroll >= maxScroll * 0.9 && currentScroll >= maxScroll - threshold) {
        if (!_loadMoreCalled && widget.onLoadMore != null) {
          _loadMoreCalled = true;
          print('✨ ScrollListener: 90% reached, offset: $currentScroll / $maxScroll, calling onLoadMore...');
          widget.onLoadMore!();
          
          // Reset flag after a delay to allow next load
          Future.delayed(const Duration(milliseconds: 800), () {
            _loadMoreCalled = false;
            print('✨ ScrollListener: Flag reset, ready for next load');
          });
        }
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset position = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final padding = mediaQuery.padding;
    final availableSpaceBelow = screenHeight - position.dy - size.height - padding.bottom - keyboardHeight;
    final availableSpaceAbove = position.dy - padding.top;
    const fixedDropdownHeight = 250.0;
    bool openAbove = availableSpaceBelow < fixedDropdownHeight && availableSpaceAbove > availableSpaceBelow;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        child: Stack(
          children: [
            // Transparent overlay covering entire screen
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // Dropdown positioned
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, openAbove ? -(fixedDropdownHeight + 4) : size.height + 4),
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping dropdown
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      _setOverlayState = setOverlayState; // Store reference for updates
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: size.width,
                          height: fixedDropdownHeight,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                autofocus: false,
                                decoration: const InputDecoration(
                                  hintText: 'Search...',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (query) {
                                  _debounce?.cancel();
                                  // Reset load flag when search query changes
                                  _loadMoreCalled = false;
                                  _debounce = Timer(const Duration(milliseconds: 300), () {
                                    setOverlayState(() {
                                      _filteredItems = query.isEmpty
                                          ? widget.items.toSet().toList()
                                          : widget.items
                                              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                                              .toSet()
                                              .toList();
                                      print('🔍 Search: query="$query", found ${_filteredItems.length} items');
                                    });
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: _filteredItems.isEmpty
                                    ? const Center(
                                        child: Text('No items found'),
                                      )
                                    : NotificationListener<ScrollNotification>(
                                        onNotification: (notification) {
                                          _checkScroll(notification);
                                          return false;
                                        },
                                        child: Scrollbar(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              final item = _filteredItems[index];
                                              return ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                dense: true,
                                                title: Text(item),
                                                onTap: () => _selectItem(item),
                                                selected: widget.value == item,
                                                selectedTileColor: Colors.blue.shade50,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Icon(
              _overlayEntry == null ? Icons.arrow_drop_down : Icons.arrow_drop_up,
            ),
          ),
          child: Text(
            widget.value.isEmpty ? widget.label : widget.value,
            style: TextStyle(
              color: widget.value.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}