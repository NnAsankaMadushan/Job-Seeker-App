import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_seeker_app/models/job.dart';
import 'package:job_seeker_app/models/job_application.dart';
import 'package:job_seeker_app/services/firebase_notification_service.dart';

class FirebaseJobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseNotificationService _notificationService = FirebaseNotificationService();

  // Get available jobs
  Stream<List<Job>> getAvailableJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'available')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Get jobs posted by current user
  Stream<List<Job>> getMyPostedJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('jobs')
        .where('providerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Get jobs applied by current user
  Stream<List<Job>> getMyAppliedJobs() async* {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      yield [];
      return;
    }

    // Get all applications by this user
    final applicationsSnapshot = await _firestore
        .collection('job_applications')
        .where('applicantId', isEqualTo: userId)
        .get();

    final jobIds = applicationsSnapshot.docs.map((doc) => doc.data()['jobId'] as String).toList();

    if (jobIds.isEmpty) {
      yield [];
      return;
    }

    // Get jobs for these applications
    yield* _firestore
        .collection('jobs')
        .where(FieldPath.documentId, whereIn: jobIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Get IDs of jobs that current user has applied to
  Future<List<String>> getAppliedJobIds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final applicationsSnapshot = await _firestore
          .collection('job_applications')
          .where('applicantId', isEqualTo: userId)
          .get();

      return applicationsSnapshot.docs
          .map((doc) => doc.data()['jobId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Post a new job
  Future<Map<String, dynamic>> postJob({
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String time,
    required double budget,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final providerName = userDoc.data()?['name'] ?? user.displayName ?? 'Unknown';

      final jobData = {
        'title': title,
        'description': description,
        'location': location,
        'date': Timestamp.fromDate(date),
        'time': time,
        'budget': budget,
        'providerId': user.uid,
        'providerName': providerName,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('jobs').add(jobData);

      return {
        'success': true,
        'message': 'Job posted successfully',
        'jobId': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error posting job: $e',
      };
    }
  }

  // Apply for a job
  Future<Map<String, dynamic>> applyForJob({
    required String jobId,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Check if already applied
      final existing = await _firestore
          .collection('job_applications')
          .where('jobId', isEqualTo: jobId)
          .where('applicantId', isEqualTo: user.uid)
          .get();

      if (existing.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'You have already applied for this job',
        };
      }

      // Get job and user data
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!jobDoc.exists) {
        return {
          'success': false,
          'message': 'Job not found',
        };
      }

      final providerId = jobDoc.data()?['providerId'] ?? '';

      // Prevent users from applying to their own jobs
      if (providerId == user.uid) {
        return {
          'success': false,
          'message': 'You cannot apply to your own job post',
        };
      }
      final jobTitle = jobDoc.data()?['title'] ?? '';
      final applicantName = userDoc.data()?['name'] ?? user.displayName ?? 'Unknown';

      final applicationData = {
        'jobId': jobId,
        'jobTitle': jobTitle,
        'providerId': providerId,
        'applicantId': user.uid,
        'applicantName': applicantName,
        'applicantImage': userDoc.data()?['profileImage'],
        'message': message,
        'status': 'pending',
        'appliedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('job_applications').add(applicationData);

      // Send notification to job provider
      if (providerId.isNotEmpty) {
        await _notificationService.createNotification(
          userId: providerId,
          type: 'application',
          title: 'New Job Application',
          message: '$applicantName applied for "$jobTitle"',
          data: {'jobId': jobId, 'applicantId': user.uid},
        );
      }

      return {
        'success': true,
        'message': 'Application submitted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error applying for job: $e',
      };
    }
  }

  // Get applications for a job
  Stream<List<JobApplication>> getJobApplications(String jobId) {
    return _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobApplication.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Get all applications for jobs posted by current user
  Stream<List<JobApplication>> getAllMyJobApplications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('job_applications')
        .where('providerId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobApplication.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Update application status
  Future<Map<String, dynamic>> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    try {
      await _firestore.collection('job_applications').doc(applicationId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get application details for notification
      final appDoc = await _firestore.collection('job_applications').doc(applicationId).get();
      final jobId = appDoc.data()?['jobId'];
      final applicantId = appDoc.data()?['applicantId'];
      final jobTitle = appDoc.data()?['jobTitle'];

      if (applicantId != null && jobTitle != null) {
        // Send notification to applicant
        await _notificationService.createNotification(
          userId: applicantId,
          type: 'application',
          title: status == 'accepted' ? 'Application Accepted!' : 'Application Status Updated',
          message: status == 'accepted'
              ? 'Your application for "$jobTitle" has been accepted!'
              : 'Your application for "$jobTitle" has been rejected.',
          data: {'jobId': jobId, 'applicationId': applicationId},
        );
      }

      // If accepted, update job status
      if (status == 'accepted' && jobId != null && applicantId != null) {
        await _firestore.collection('jobs').doc(jobId).update({
          'status': 'in_progress',
          'assignedTo': applicantId,
        });
      }

      return {
        'success': true,
        'message': 'Application ${status == "accepted" ? "accepted" : "rejected"}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating application: $e',
      };
    }
  }

  // Search jobs
  Stream<List<Job>> searchJobs(String query) {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'available')
        .orderBy('title')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // Delete job
  Future<bool> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
