/// Runtime options for an RPC.
class CallOptions {
  final Map<String, String> metadata;

  CallOptions._(this.metadata);

  /// Creates a [CallOptions] object.
  factory CallOptions({Map<String, String>? metadata}) {
    return CallOptions._(Map.unmodifiable(metadata ?? {}));
  }

  CallOptions mergedWith(CallOptions? other) {
    if (other == null) return this;
    final mergedMetadata = Map.from(metadata)..addAll(other.metadata);
    return CallOptions._(Map.unmodifiable(mergedMetadata));
  }
}
