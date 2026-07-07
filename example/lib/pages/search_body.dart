import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cupertino/flutter_cupertino.dart';

/// Body for the searchable scaffold demo. It runs in its own FlutterEngine
/// inside the native SwiftUI ScrollView and listens to
/// [CupertinoNativeScaffold.searchState] — the live snapshot of the native
/// `.searchable` field — to decide what to render below the search bar:
///
///  * idle          → the full list
///  * active, empty → search suggestions
///  * active, typing→ a loading spinner, then filtered results (or "no results")
///
/// The native search bar (placeholder, placement, expand-and-hide-title
/// behavior) is owned by SwiftUI; everything below it is plain Flutter that we
/// customize here.
class SearchBody extends StatefulWidget {
  const SearchBody({super.key});

  @override
  State<SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<SearchBody> {
  static const _all = <String>[
    'SwiftUI',
    'Swift',
    'Objective-C',
    'Python',
    'JavaScript',
    'TypeScript',
    'Dart',
    'Kotlin',
    'Java',
    'Rust',
    'Go',
    'C++',
    'Ruby',
    'PHP',
  ];

  /// Popular queries to hint while the field is focused but empty.
  static const _suggestions = <String>['Swift', 'Python', 'JavaScript', 'Dart'];

  bool _active = false;
  bool _loading = false;
  String _query = '';
  List<String> _results = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    CupertinoNativeScaffold.searchState.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    CupertinoNativeScaffold.searchState.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    final state = CupertinoNativeScaffold.searchState.value;
    _debounce?.cancel();

    if (state.isActive && state.query.isNotEmpty) {
      // Simulate an async lookup so the loader is visible; a real app would
      // hit a database or network here.
      setState(() {
        _active = true;
        _query = state.query;
        _loading = true;
      });
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final q = state.query.toLowerCase();
        setState(() {
          _results =
              _all.where((e) => e.toLowerCase().contains(q)).toList();
          _loading = false;
        });
      });
    } else {
      setState(() {
        _active = state.isActive;
        _query = state.query;
        _loading = false;
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) {
      return _list(_all);
    }
    if (_query.isEmpty) {
      return _suggestionsView();
    }
    if (_loading) {
      return _loader();
    }
    if (_results.isEmpty) {
      return _empty();
    }
    return _list(_results);
  }

  Widget _list(List<String> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in items)
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(item),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _suggestionsView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Suggestions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        for (final s in _suggestions)
          ListTile(
            leading: const Icon(Icons.north_west, size: 18),
            title: Text(s),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _loader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          'No results for "$_query"',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
