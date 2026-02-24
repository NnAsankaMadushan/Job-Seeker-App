import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_seeker_app/models/message.dart';
import 'package:job_seeker_app/services/message_encryption_service.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageEncryptionService _encryptionService = MessageEncryptionService.instance;

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
          final encryptedLastMessage = data['lastMessage'] as String? ?? '';
          final decryptedLastMessage = await _encryptionService.decryptMessage(
            encryptedText: encryptedLastMessage,
            conversationId: doc.id,
          );

          lastMessage = Message(
            id: '',
            senderId: data['lastMessageSenderId'] ?? '',
            senderName: '',
            receiverId: '',
            content: decryptedLastMessage,
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
        .asyncMap((snapshot) async {
      return Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final encryptedContent = data['content'] as String? ?? '';
        final decryptedContent = await _encryptionService.decryptMessage(
          encryptedText: encryptedContent,
          conversationId: conversationId,
        );

        return Message(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? '',
          receiverId: data['receiverId'] ?? '',
          content: decryptedContent,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }));
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
      final encryptedContent = await _encryptionService.encryptMessage(
        plainText: content,
        conversationId: conversationId,
      );
      final conversationRef = _firestore.collection('conversations').doc(
            conversationId,
          );
      final participants = [user.uid, receiverId]..sort();

      // Get sender name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final senderName = userDoc.data()?['name'] ?? user.displayName ?? 'Unknown';

      final messageData = {
        'senderId': user.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'content': encryptedContent,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isEncrypted': true,
      };

      // Ensure conversation exists before writing to the messages subcollection.
      await conversationRef.set({
        'participants': participants,
      }, SetOptions(merge: true));

      // Add message to conversation
      final messageRef = await conversationRef.collection('messages').add(messageData);

      // Update conversation metadata
      await conversationRef.set({
        'participants': participants,
        'lastMessage': encryptedContent,
        'lastMessageSenderId': user.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_${receiverId}': FieldValue.increment(1),
        'unreadCount_${user.uid}': 0, // Reset sender's unread count
        'lastMessageEncrypted': true,
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
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return {
          'success': false,
          'error': 'Permission denied by Firestore rules for chat writes.',
        };
      }
      return {
        'success': false,
        'error': 'Error sending message: ${e.message ?? e.code}',
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
