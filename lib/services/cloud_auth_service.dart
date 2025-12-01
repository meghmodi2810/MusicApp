import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Cloud-based authentication service using Firebase
class CloudAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generate 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Send OTP via email (simplified version - use SendGrid or similar in production)
  Future<String> sendOTPToEmail(String email) async {
    final otp = _generateOTP();
    
    // Store OTP in Firestore with expiry time (5 minutes)
    await _firestore.collection('otp_codes').doc(email).set({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': DateTime.now().add(Duration(minutes: 5)).millisecondsSinceEpoch,
    });
    
    // TODO: Send email using your preferred email service
    // For now, we'll return the OTP for testing
    debugPrint('OTP for $email: $otp');
    
    return otp;
  }
  
  // Verify OTP
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final doc = await _firestore.collection('otp_codes').doc(email).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = data['expiresAt'] as int;
      
      // Check if OTP is expired
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _firestore.collection('otp_codes').doc(email).delete();
        return false;
      }
      
      // Verify OTP
      if (storedOTP == otp) {
        await _firestore.collection('otp_codes').doc(email).delete();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }
  
  // Register new user
  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String password,
    required String displayName,
    required String otp,
  }) async {
    try {
      // Verify OTP first
      final isOTPValid = await verifyOTP(email, otp);
      if (!isOTPValid) {
        throw Exception('Invalid or expired OTP');
      }
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user');
      
      // Update display name
      await user.updateDisplayName(displayName);
      
      // Store additional user data in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'listeningHistory': [],
        'favoriteArtists': [],
        'playlists': [],
      });
      
      return {
        'id': user.uid,
        'email': email,
        'display_name': displayName,
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
  
  // Login user
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) throw Exception('Login failed');
      
      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      
      return {
        'id': user.uid,
        'email': user.email,
        'display_name': data?['displayName'] ?? user.displayName ?? 'User',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }
  
  // Sync user listening history to cloud
  Future<void> syncListeningHistory(List<Map<String, dynamic>> history) async {
    if (!isLoggedIn) return;
    
    await _firestore.collection('users').doc(currentUser!.uid).update({
      'listeningHistory': history,
      'lastSync': FieldValue.serverTimestamp(),
    });
  }
  
  // Get user listening history from cloud
  Future<List<Map<String, dynamic>>> getListeningHistory() async {
    if (!isLoggedIn) return [];
    
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    final data = doc.data();
    
    if (data == null || data['listeningHistory'] == null) return [];
    
    return List<Map<String, dynamic>>.from(data['listeningHistory']);
  }
}
