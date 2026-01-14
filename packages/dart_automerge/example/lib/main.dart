import 'dart:async';
import 'dart:math';

import 'package:dart_automerge/dart_automerge.dart';
import 'package:flutter/material.dart';

/// Entry point for the Automerge Sync Demo.
///
/// Initializes the Rust bridge ([RustLib.init()]) before running the Flutter app.
Future<void> main() async {
  // Ensure the Rust library is initialized before using any Automerge APIs.
  // This loads the compiled native library and sets up the FFI bridge.
  await RustLib.init();
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Automerge Sync Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TwoDocsSyncPage(),
    );
  }
}

/// A page demonstrating real-time synchronization between two local [Doc] instances.
///
/// This simulates a distributed system where "Device A" and "Device B" are
/// modified independently and synced manually via a simulated network loop.
class TwoDocsSyncPage extends StatefulWidget {
  const TwoDocsSyncPage({super.key});

  @override
  State<TwoDocsSyncPage> createState() => _TwoDocsSyncPageState();
}

class _TwoDocsSyncPageState extends State<TwoDocsSyncPage> {
  // We simulate two devices: "Alice" and "Bob".
  // In a real app, these would be on separate devices, but here we keep them
  // in memory to demonstrate the sync protocol locally.
  Doc? _docA;
  Doc? _docB;

  // Sync states for the connection between A and B.
  // Automerge synchronization is connection-oriented. Each peer maintains a
  // [SyncState] for every other peer it talks to.
  //
  // [_syncStateAtoB] is maintained by A to track what it thinks B has.
  // [_syncStateBtoA] is maintained by B to track what it thinks A has.
  SyncState? _syncStateAtoB;
  SyncState? _syncStateBtoA;

  // Local state mirrors for UI rendering.
  // Automerge Docs are opaque handles; we "hydrate" them into pure Dart Maps/Lists
  // for easy consumption by Flutter widgets.
  Map<String, dynamic> _dataA = {};
  Map<String, dynamic> _dataB = {};

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initDocs();
  }

  /// Initializes the local documents, simulating a "shared start" state.
  Future<void> _initDocs() async {
    // 1. Create Doc A and initialize its state.
    //    We explicitly initialize the 'todos' list here.
    final docA = await Doc.newDoc();
    await docA.update((root) async {
      return {'todos': <Map<String, dynamic>>[]};
    });

    // 2. Clone Doc B from Doc A.
    //    This simulates a scenario where Device B starts with a copy of the
    //    application state (e.g. pulled from a server or shared file).
    //    Crucially, this ensures both docs share the same history for the
    //    'todos' list creation, preventing a merge conflict where one list
    //    completely overwrites the other.
    final docB = await docA.fork();

    // 3. Create SyncStates.
    //    These are persistent state machines used by the sync protocol to minimize
    //    data transfer. They track "Have/Need" bloom filters.
    final syncA = await SyncState.create();
    final syncB = await SyncState.create();

    setState(() {
      _docA = docA;
      _docB = docB;
      _syncStateAtoB = syncA;
      _syncStateBtoA = syncB;
    });

    await _refreshData();
  }

  /// Reads the current value from both docs and updates the UI state.
  ///
  /// This calls [doc.value], which internally uses [autosurgeon] to hydrate
  /// the Rust CRDT state into a standard Dart [Map<String, dynamic>].
  Future<void> _refreshData() async {
    if (_docA == null || _docB == null) return;
    final valA = await _docA!.value;
    final valB = await _docB!.value;
    setState(() {
      _dataA = valA;
      _dataB = valB;
    });
  }

  /// Adds a new Todo item to the specified [doc].
  ///
  /// Uses [doc.update()] to modify the state in a transaction.
  /// This change is applied locally immediately and will be merged to the
  /// other doc during the next [_sync()] call.
  Future<void> _addTodo(Doc doc, String owner) async {
    await doc.update((root) {
      // 1. Get the current list of todos (or empty list if missing)
      final todos =
          (root['todos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // 2. Add the new item.
      //    We rely on Random ID to avoid collisions, though Automerge handles
      //    concurrent inserts into lists gracefully even without explicit IDs.
      todos.add({
        'id':
            DateTime.now().millisecondsSinceEpoch.toString() +
            Random().nextInt(1000).toString(),
        'title': '$owner task ${todos.length + 1}',
        'done': false,
        'created_by': owner,
      });

      // 3. Return the updated root map.
      return {'todos': todos};
    });
    await _refreshData();
  }

  /// Toggles the 'done' status of a Todo at [index].
  Future<void> _toggleTodo(Doc doc, int index) async {
    await doc.update((root) {
      final todos =
          (root['todos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (index < todos.length) {
        // Modifying a field deep in the JSON structure.
        // Automerge tracks this precise change (not a full object replacement).
        todos[index]['done'] = !todos[index]['done'];
      }
      return {'todos': todos};
    });
    await _refreshData();
  }

  /// Simulates a bidirectional network sync between Doc A and Doc B.
  ///
  /// The Automerge sync protocol works by exchanging messages until both
  /// sides report that they have nothing more to send.
  Future<void> _sync() async {
    if (_isSyncing || _docA == null || _docB == null) return;
    setState(() => _isSyncing = true);

    try {
      bool changed = true;
      int rounds = 0;

      // Loop until no more messages are generated (convergence).
      // In a real app, this would be an event loop over a WebSocket or peer connection.
      while (changed && rounds < 10) {
        changed = false;
        rounds++;

        // 1. Generate message from A to B (A tells B what it knows/needs)
        final msgA = await _docA!.generateSyncMessage(_syncStateAtoB!);
        if (msgA != null) {
          // 2. B receives message from A, updates its state, and maybe generating a response next
          await _docB!.receiveSyncMessage(_syncStateBtoA!, msgA);
          changed = true;
        }

        // 3. Generate message from B to A (B responds with missing data)
        final msgB = await _docB!.generateSyncMessage(_syncStateBtoA!);
        if (msgB != null) {
          // 4. A receives message from B
          await _docA!.receiveSyncMessage(_syncStateAtoB!, msgB);
          changed = true;
        }
      }
    } finally {
      // Update UI to show the merged state
      await _refreshData();
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_docA == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automerge Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _sync,
            tooltip: 'Sync Now',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSyncing) const LinearProgressIndicator(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _DocView(
                    label: 'Device A (Alice)',
                    data: _dataA,
                    onAdd: () => _addTodo(_docA!, 'Alice'),
                    onToggle: (idx) => _toggleTodo(_docA!, idx),
                    color: Colors.blue.shade50,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _DocView(
                    label: 'Device B (Bob)',
                    data: _dataB,
                    onAdd: () => _addTodo(_docB!, 'Bob'),
                    onToggle: (idx) => _toggleTodo(_docB!, idx),
                    color: Colors.green.shade50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sync,
        icon: const Icon(Icons.sync),
        label: const Text('Sync Docs'),
      ),
    );
  }
}

/// A reusable widget to display the state of a single Document.
class _DocView extends StatelessWidget {
  final String label;
  final Map<String, dynamic> data;
  final VoidCallback onAdd;
  final Function(int) onToggle;
  final Color color;

  const _DocView({
    required this.label,
    required this.data,
    required this.onAdd,
    required this.onToggle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final todos = (data['todos'] as List?) ?? [];

    return Container(
      color: color,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                final title = todo['title'] ?? 'Untitled';
                final isDone = todo['done'] == true;
                final owner = todo['created_by'] ?? '?';

                return ListTile(
                  title: Text(
                    title,
                    style: TextStyle(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('by $owner'),
                  leading: Checkbox(
                    value: isDone,
                    onChanged: (_) => onToggle(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
