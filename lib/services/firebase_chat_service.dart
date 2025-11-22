import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_seeker_app/models/message.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get conversations
  Stream<List<Conversation>> getConversations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Conversation> conversations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // Get other user's data
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        final userName = userDoc.data()?['name'] ?? 'Unknown';
        final userImage = userDoc.data()?['profileImage'];

        // Get last message
        Message? lastMessage;
        if (data['lastMessage'] != null) {
          lastMessage = Message(
            id: '',
            senderId: data['lastMessageSenderId'] ?? '',
            senderName: '',
            receiverId: '',
            content: data['lastMessage'] ?? '',
            timestamp: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }

        conversations.add(Conversation(
          id: doc.id,
          userId: otherUserId,
          userName: userName,
          userImage: userImage,
          lastMessage: lastMessage,
          unreadCount: data['unreadCount_$userId'] ?? 0,
        ));
      }

      return conversations;
    });
  }

  // Get messages between users
  Stream<List<Message>> getMessages(String otherUserId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    final conversationId = _getConversationId(userId, otherUserId);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Message(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? '',
          receiverId: data['receiverId'] ?? '',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final conversationId = _getConversationId(user.uid, receiverId);

      // Get sender name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final senderName = userDoc.data()?['name'] ?? user.displayName ?? 'Unknown';

      final messageData = {
        'senderId': user.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add message to conversation
      final messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation metadata
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [user.uid, receiverId],
        'lastMessage': content,
        'lastMessageSenderId': user.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${receiverId}': FieldValue.increment(1),
        'unreadCount_${user.uid}': 0, // Reset sender's unread count
      }, SetOptions(merge: true));

      return {
        'success': true,
        'message': Message(
          id: messageRef.id,
          senderId: user.uid,
          senderName: senderName,
          receiverId: receiverId,
          content: content,
          timestamp: DateTime.now(),
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error sending message: $e',
      };
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String otherUserId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final conversationId = _getConversationId(userId, otherUserId);

      // Mark all unread messages as read
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }

      // Reset unread count - use set with merge to avoid errors if document doesn't exist
      await _firestore.collection('conversations').doc(conversationId).set({
        'unreadCount_$userId': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      // Ignore errors
    }
  }

  // Get conversation ID (consistent regardless of sender/receiver order)
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
