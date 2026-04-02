import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_seeker_app/models/applicant_rating_summary.dart';
import 'package:job_seeker_app/models/user_rating.dart';

class FirebaseRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ApplicantRatingSummary> getApplicantRatingSummary(
    String applicantId,
  ) async {
    if (applicantId.isEmpty) {
      return const ApplicantRatingSummary.empty();
    }

    final snapshot = await _firestore
        .collection('user_ratings')
        .where('ratedUserId', isEqualTo: applicantId)
        .get();

    if (snapshot.docs.isEmpty) {
      return const ApplicantRatingSummary.empty();
    }

    final ratings =
        snapshot.docs.map((doc) => doc.data()['rating']).whereType<num>();

    return ApplicantRatingSummary.fromRatings(ratings);
  }

  Stream<List<UserRating>> watchUserRatings(
    String userId, {
    int limit = 5,
  }) {
    if (userId.isEmpty) {
      return Stream.value(const <UserRating>[]);
    }

    final query = _firestore
        .collection('user_ratings')
        .where('ratedUserId', isEqualTo: userId);

    return query.snapshots().map((snapshot) {
      final ratings = snapshot.docs
          .map((doc) => UserRating.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (limit > 0 && ratings.length > limit) {
        return ratings.take(limit).toList();
      }

      return ratings;
    });
  }

  Future<Map<String, dynamic>> submitApplicantRating({
    required String applicationId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      if (rating < 1 || rating > 5) {
        return {
          'success': false,
          'message': 'Rating must be between 1 and 5 stars',
        };
      }

      final trimmedFeedback = feedback?.trim() ?? '';
      if (trimmedFeedback.length > 300) {
        return {
          'success': false,
          'message': 'Feedback must be 300 characters or less',
        };
      }

      final applicationRef =
          _firestore.collection('job_applications').doc(applicationId);
      final applicationSnapshot = await applicationRef.get();
      if (!applicationSnapshot.exists) {
        return {
          'success': false,
          'message': 'Application not found',
        };
      }

      final applicationData = applicationSnapshot.data();
      if (applicationData == null) {
        return {
          'success': false,
          'message': 'Application data is unavailable',
        };
      }

      final providerId = (applicationData['providerId'] ?? '').toString();
      final applicantId = (applicationData['applicantId'] ?? '').toString();
      final jobId = (applicationData['jobId'] ?? '').toString();

      if (providerId != user.uid) {
        return {
          'success': false,
          'message': 'You can only rate applicants for your own jobs',
        };
      }

      if (applicantId.isEmpty || jobId.isEmpty) {
        return {
          'success': false,
          'message': 'Application data is incomplete',
        };
      }

      if (applicantId == user.uid) {
        return {
          'success': false,
          'message': 'You cannot rate yourself',
        };
      }

      final jobSnapshot = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobSnapshot.exists) {
        return {
          'success': false,
          'message': 'Job not found',
        };
      }

      final jobData = jobSnapshot.data();
      final jobProviderId = (jobData?['providerId'] ?? '').toString();
      final jobTitle = (jobData?['title'] ?? '').toString();
      if (jobProviderId != user.uid) {
        return {
          'success': false,
          'message': 'You can only rate applicants for your own jobs',
        };
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final raterName =
          (userDoc.data()?['name'] ?? user.displayName ?? 'Provider')
              .toString();

      final ratingRef =
          _firestore.collection('user_ratings').doc(applicationId);
      final existingRating = await ratingRef.get();
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'applicationId': applicationId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'ratedUserId': applicantId,
        'raterId': user.uid,
        'raterName': raterName,
        'rating': rating,
        'feedback': trimmedFeedback,
        'updatedAt': now,
      };

      if (existingRating.exists) {
        final existingData = existingRating.data();
        payload['createdAt'] = existingData?['createdAt'] ?? now;
        await ratingRef.update(payload);
        return {
          'success': true,
          'message': 'Feedback updated successfully',
        };
      }

      payload['createdAt'] = now;
      await ratingRef.set(payload);

      return {
        'success': true,
        'message': 'Feedback submitted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting feedback: $e',
      };
    }
  }
}
