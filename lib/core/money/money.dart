/// Every API amount is EUR (API.md §0.2), even products labelled `"USD"`.
/// Stored as integer EUR cents so arithmetic never touches `double`
/// (Rules.md: "Parse money as decimal/cents, never accumulate doubles").
class Money {
  const Money(this.eurCents);

  final int eurCents;

  /// Parses an API decimal string like `"2.1000"` into EUR cents.
  factory Money.parseEur(String apiAmount) {
    final negative = apiAmount.startsWith('-');
    final unsigned = negative ? apiAmount.substring(1) : apiAmount;
    final parts = unsigned.split('.');
    final whole = int.parse(parts.isEmpty ? '0' : parts[0]);
    final fraction = parts.length > 1 ? parts[1] : '';
    final cents = int.parse(fraction.padRight(2, '0').substring(0, 2));
    final total = whole * 100 + cents;
    return Money(negative ? -total : total);
  }

  double get eurValue => eurCents / 100;

  Money operator +(Money other) => Money(eurCents + other.eurCents);
  Money operator -(Money other) => Money(eurCents - other.eurCents);

  bool operator <(Money other) => eurCents < other.eurCents;
  bool operator <=(Money other) => eurCents <= other.eurCents;
  bool operator >(Money other) => eurCents > other.eurCents;
  bool operator >=(Money other) => eurCents >= other.eurCents;

  @override
  bool operator ==(Object other) =>
      other is Money && other.eurCents == eurCents;

  @override
  int get hashCode => eurCents.hashCode;

  @override
  String toString() => 'Money($eurCents eur-cents)';
}
