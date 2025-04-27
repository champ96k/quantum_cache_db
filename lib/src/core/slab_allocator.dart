import 'dart:typed_data';

/// A slab allocator that manages fixed-size blocks of memory
class SlabAllocator {
  final int blockSize;
  final int slabSize;
  final List<Uint8List> _slabs = [];
  final List<bool> _freeBlocks = [];

  SlabAllocator({
    this.blockSize = 4096, // 4KB blocks
    this.slabSize = 1000, // 1000 blocks per slab
  });

  /// Allocate a new block of memory
  int allocate() {
    // Find first free block
    for (int i = 0; i < _freeBlocks.length; i++) {
      if (_freeBlocks[i]) {
        _freeBlocks[i] = false;
        return i;
      }
    }

    // No free blocks, create new slab
    final newSlab = Uint8List(slabSize * blockSize);
    _slabs.add(newSlab);

    // Add new free blocks
    final startIndex = _freeBlocks.length;
    for (int i = 0; i < slabSize; i++) {
      _freeBlocks.add(true);
    }

    // Mark first block as used and return its index
    _freeBlocks[startIndex] = false;
    return startIndex;
  }

  /// Free a block of memory
  void free(int blockIndex) {
    if (blockIndex >= 0 && blockIndex < _freeBlocks.length) {
      _freeBlocks[blockIndex] = true;
    }
  }

  /// Get a view of the block's memory
  Uint8List getBlock(int blockIndex) {
    final slabIndex = blockIndex ~/ slabSize;
    final blockOffset = (blockIndex % slabSize) * blockSize;
    return _slabs[slabIndex].sublist(blockOffset, blockOffset + blockSize);
  }

  /// Get the total number of allocated blocks
  int get totalBlocks => _freeBlocks.length;

  /// Get the number of free blocks
  int get freeBlocks => _freeBlocks.where((b) => b).length;
}
