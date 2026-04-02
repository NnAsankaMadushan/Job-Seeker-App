class ApplicantRatingSummary {
  final double averageRating;
  final int ratingCount;

  const ApplicantRatingSummary({
    required this.averageRating,
    required this.ratingCount,
  });

  const ApplicantRatingSummary.empty()
      : averageRating = 0,
        ratingCount = 0;

  factory ApplicantRatingSummary.fromRatings(Iterable<num> ratings) {
    final values = ratings.map((rating) => rating.toDouble()).toList();
    if (values.isEmpty) {
      return const ApplicantRatingSummary.empty();
    }

    final total = values.fold<double>(0, (sum, rating) => sum + rating);
    return ApplicantRatingSummary(
      averageRating: total / values.length,
      ratingCount: values.length,
    );
  }

  bool get hasRatings => ratingCount > 0;

  String get averageLabel => averageRating.toStringAsFixed(1);
}
