import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_seeker_app/models/message.dart';
import 'package:job_seeker_app/services/message_encryption_service.dart';

class FirebaseChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageEncryptionService _encryptionService =
      MessageEncryptionService.instance;

  // Cache for sender names to optimize sending
  final Map<String, String> _userNameCache = {};

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
      final conversations = await Future.wait(
        snapshot.docs.map((doc) => _buildConversation(
              doc: doc,
              currentUserId: userId,
            )),
      );

      return conversations.whereType<Conversation>().toList();
    });
  }

  Future<Conversation?> _buildConversation({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String currentUserId,
  }) async {
    final data = doc.data();
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return null;
    }

    String userName = 'Unknown';
    String? userImage;

    try {
      final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      final userData = userDoc.data();
      if (userData != null) {
        final rawName = userData['name'] as String?;
        final trimmedName = rawName?.trim();
        userName = (trimmedName != null && trimmedName.isNotEmpty)
            ? trimmedName
            : 'Unknown';
        userImage = userData['profileImage'] as String?;
      }
    } catch (_) {
      // Keep the conversation visible even if profile data cannot be fetched.
    }

    Message? lastMessage;
    final encryptedLastMessage = data['lastMessage'] as String?;
    if (encryptedLastMessage != null && encryptedLastMessage.isNotEmpty) {
      final decryptedLastMessage = await _encryptionService.decryptMessage(
        encryptedText: encryptedLastMessage,
        conversationId: doc.id,
      );

      lastMessage = Message(
        id: '',
        senderId: data['lastMessageSenderId'] as String? ?? '',
        senderName: '',
        receiverId: '',
        content: decryptedLastMessage,
        timestamp:
            (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }

    return Conversation(
      id: doc.id,
      userId: otherUserId,
      userName: userName,
      userImage: userImage,
      lastMessage: lastMessage,
      unreadCount: (data['unreadCount_$currentUserId'] as num?)?.toInt() ?? 0,
    );
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
      return Future.wait(
        snapshot.docs.map(
          (doc) => _buildMessage(
            doc: doc,
            conversationId: conversationId,
          ),
        ),
      );
    });
  }

  Future<Message> _buildMessage({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String conversationId,
  }) async {
    final data = doc.data();
    final encryptedContent = data['content'] as String? ?? '';
    final decryptedContent = await _encryptionService.decryptMessage(
      encryptedText: encryptedContent,
      conversationId: conversationId,
    );

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      content: decryptedContent,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
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
      final conversationRef =
          _firestore.collection('conversations').doc(conversationId);
      final messageRef = conversationRef.collection('messages').doc();
      final participants = [user.uid, receiverId]..sort();

      final senderName = await _resolveSenderName(user);

      final messageData = {
        'senderId': user.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'content': encryptedContent,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'isEncrypted': true,
      };

      final batch = _firestore.batch();
      batch.set(
        conversationRef,
        {
          'participants': participants,
          'lastMessage': encryptedContent,
          'lastMessageSenderId': user.uid,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount_$receiverId': FieldValue.increment(1),
          'unreadCount_${user.uid}': 0,
          'lastMessageEncrypted': true,
        },
        SetOptions(merge: true),
      );
      batch.set(messageRef, messageData);
      await batch.commit();

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

      if (messages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in messages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }

      // Reset unread count - use set with merge to avoid errors if document doesn't exist
      await _firestore.collection('conversations').doc(conversationId).set(
        {
          'unreadCount_$userId': 0,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Ignore errors
    }
  }

  Future<String> _resolveSenderName(User user) async {
    final cachedName = _userNameCache[user.uid];
    if (cachedName != null && cachedName.trim().isNotEmpty) {
      return cachedName;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final name = (userDoc.data()?['name'] as String?)?.trim();
      final resolvedName = (name != null && name.isNotEmpty)
          ? name
          : user.displayName ?? 'Unknown';
      _userNameCache[user.uid] = resolvedName;
      return resolvedName;
    } catch (_) {
      final fallbackName = user.displayName?.trim();
      final resolvedName = (fallbackName != null && fallbackName.isNotEmpty)
          ? fallbackName
          : 'Unknown';
      _userNameCache[user.uid] = resolvedName;
      return resolvedName;
    }
  }

  // Get conversation ID (consistent regardless of sender/receiver order)
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
