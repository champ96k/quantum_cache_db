// # B-tree implementation

class BTreeIndex {
  final int order;
  _BTreeNode? _root;

  BTreeIndex([this.order = 32]);

  void insert(dynamic key, int position) {
    _root ??= _BTreeNode(order, true);

    if (_root!.keys.length == 2 * order - 1) {
      final newRoot = _BTreeNode(order, false);
      newRoot.children.add(_root);
      _splitChild(newRoot, 0);
      _root = newRoot;
    }

    _insertNonFull(_root!, key, position);
  }

  int? find(dynamic key) {
    return _root?._find(key);
  }

  void _insertNonFull(_BTreeNode node, dynamic key, int position) {
    // Implementation of B-tree insert
  }

  void _splitChild(_BTreeNode parent, int index) {
    // Implementation of B-tree split
  }
}

class _BTreeNode {
  final int order;
  final bool isLeaf;
  final List<dynamic> keys;
  final List<int> values;
  final List<_BTreeNode?> children;

  _BTreeNode(this.order, this.isLeaf)
      : keys = [],
        values = [],
        children = isLeaf ? [] : List.filled(order * 2, null);

  int? _find(dynamic key) {
    var i = 0;
    while (i < keys.length && key.compareTo(keys[i]) > 0) {
      i++;
    }

    if (i < keys.length && key == keys[i]) {
      return values[i];
    }

    return isLeaf ? null : children[i]?._find(key);
  }
}
